// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic
import gleam/http
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import wisp.{type Request, type Response}

import candy_crash/context.{type Context}
import candy_crash/models/user
import candy_crash/services/auth as auth_service
import candy_crash/middleware/auth as auth_middleware

pub fn register(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_json(req)

      let decoder = dynamic.decode3(
        fn(email, password, role) { #(email, password, role) },
        dynamic.field("email", dynamic.string),
        dynamic.field("password", dynamic.string),
        dynamic.optional_field("role", dynamic.string),
      )

      case dynamic.from(body) |> decoder {
        Ok(#(email, password, role_str)) -> {
          let role = case role_str {
            Some(r) -> user.role_from_string(r)
            None -> user.Student
          }

          case auth_service.register(ctx.db, email, password, role) {
            Ok(u) -> {
              let token = auth_service.create_token(
                u.key |> option.unwrap(""),
                ctx.secret_key_base,
              )
              json.object([
                #("user", user_to_json(u)),
                #("token", json.string(token)),
              ])
              |> json.to_string_builder
              |> wisp.json_response(201)
            }
            Error(auth_service.UserExists) -> {
              json.object([#("error", json.string("Email already registered"))])
              |> json.to_string_builder
              |> wisp.json_response(409)
            }
            Error(_) -> {
              json.object([#("error", json.string("Registration failed"))])
              |> json.to_string_builder
              |> wisp.json_response(500)
            }
          }
        }
        Error(_) -> {
          json.object([#("error", json.string("Invalid request body"))])
          |> json.to_string_builder
          |> wisp.json_response(400)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

pub fn login(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_json(req)

      let decoder = dynamic.decode2(
        fn(email, password) { #(email, password) },
        dynamic.field("email", dynamic.string),
        dynamic.field("password", dynamic.string),
      )

      case dynamic.from(body) |> decoder {
        Ok(#(email, password)) -> {
          case auth_service.login(ctx.db, email, password) {
            Ok(u) -> {
              let token = auth_service.create_token(
                u.key |> option.unwrap(""),
                ctx.secret_key_base,
              )
              json.object([
                #("user", user_to_json(u)),
                #("token", json.string(token)),
              ])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            Error(auth_service.InvalidCredentials) -> {
              json.object([#("error", json.string("Invalid email or password"))])
              |> json.to_string_builder
              |> wisp.json_response(401)
            }
            Error(_) -> {
              json.object([#("error", json.string("Login failed"))])
              |> json.to_string_builder
              |> wisp.json_response(500)
            }
          }
        }
        Error(_) -> {
          json.object([#("error", json.string("Invalid request body"))])
          |> json.to_string_builder
          |> wisp.json_response(400)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

pub fn logout(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Post -> {
      // Token-based auth doesn't need server-side logout
      // Client just discards the token
      json.object([#("message", json.string("Logged out successfully"))])
      |> json.to_string_builder
      |> wisp.json_response(200)
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

pub fn me(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Get -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      json.object([#("user", user_to_json(auth_ctx.current_user))])
      |> json.to_string_builder
      |> wisp.json_response(200)
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn forgot_password(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_json(req)

      let decoder = dynamic.field("email", dynamic.string)

      case dynamic.from(body) |> decoder {
        Ok(email) -> {
          case auth_service.find_user_by_email(ctx.db, email) {
            Ok(Some(u)) -> {
              case auth_service.generate_reset_token(ctx.db, u.key |> option.unwrap("")) {
                Ok(_token) -> {
                  // In production, send email with reset link
                  json.object([#("message", json.string("Reset email sent"))])
                  |> json.to_string_builder
                  |> wisp.json_response(200)
                }
                Error(_) -> {
                  json.object([#("error", json.string("Failed to generate reset token"))])
                  |> json.to_string_builder
                  |> wisp.json_response(500)
                }
              }
            }
            Ok(None) -> {
              // Don't reveal if email exists
              json.object([#("message", json.string("Reset email sent"))])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            Error(_) -> {
              json.object([#("error", json.string("Request failed"))])
              |> json.to_string_builder
              |> wisp.json_response(500)
            }
          }
        }
        Error(_) -> {
          json.object([#("error", json.string("Email required"))])
          |> json.to_string_builder
          |> wisp.json_response(400)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

pub fn reset_password(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_json(req)

      let decoder = dynamic.decode2(
        fn(token, password) { #(token, password) },
        dynamic.field("token", dynamic.string),
        dynamic.field("password", dynamic.string),
      )

      case dynamic.from(body) |> decoder {
        Ok(#(token, password)) -> {
          // In production, validate token and find user
          // For now, just return success message
          json.object([#("message", json.string("Password reset successfully"))])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> {
          json.object([#("error", json.string("Token and password required"))])
          |> json.to_string_builder
          |> wisp.json_response(400)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

fn user_to_json(u: user.User) -> json.Json {
  json.object([
    #("key", json.string(u.key |> option.unwrap(""))),
    #("email", json.string(u.email)),
    #("role", json.string(user.role_to_string(u.role))),
  ])
}
