// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/http
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

import candy_crash/context.{type AuthContext, type Context, AuthContext}
import candy_crash/models/user.{type User}
import candy_crash/services/auth as auth_service

pub fn require_auth(
  req: Request,
  ctx: Context,
  handler: fn(AuthContext) -> Response,
) -> Response {
  case get_bearer_token(req) {
    None -> unauthorized("Missing authorization header")
    Some(token) -> {
      case auth_service.verify_token(token, ctx.secret_key_base) {
        Ok(user_key) -> {
          case auth_service.get_user_by_key(ctx.db, user_key) {
            Ok(Some(user)) -> {
              let auth_ctx = AuthContext(
                db: ctx.db,
                secret_key_base: ctx.secret_key_base,
                current_user: user,
              )
              handler(auth_ctx)
            }
            Ok(None) -> unauthorized("User not found")
            Error(_) -> unauthorized("Invalid token")
          }
        }
        Error(_) -> unauthorized("Invalid token")
      }
    }
  }
}

pub fn require_instructor(
  auth_ctx: AuthContext,
  handler: fn(AuthContext) -> Response,
) -> Response {
  case user.is_instructor(auth_ctx.current_user) {
    True -> handler(auth_ctx)
    False -> forbidden("Instructor access required")
  }
}

pub fn require_admin(
  auth_ctx: AuthContext,
  handler: fn(AuthContext) -> Response,
) -> Response {
  case user.is_admin(auth_ctx.current_user) {
    True -> handler(auth_ctx)
    False -> forbidden("Admin access required")
  }
}

pub fn optional_auth(
  req: Request,
  ctx: Context,
  handler: fn(Option(User)) -> Response,
) -> Response {
  case get_bearer_token(req) {
    None -> handler(None)
    Some(token) -> {
      case auth_service.verify_token(token, ctx.secret_key_base) {
        Ok(user_key) -> {
          case auth_service.get_user_by_key(ctx.db, user_key) {
            Ok(Some(user)) -> handler(Some(user))
            _ -> handler(None)
          }
        }
        Error(_) -> handler(None)
      }
    }
  }
}

fn get_bearer_token(req: Request) -> Option(String) {
  case list.find(req.headers, fn(h) { h.0 == "authorization" }) {
    Ok(#(_, value)) -> {
      case string.split(value, " ") {
        ["Bearer", token] -> Some(token)
        ["bearer", token] -> Some(token)
        _ -> None
      }
    }
    Error(_) -> None
  }
}

fn unauthorized(message: String) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(401)
}

fn forbidden(message: String) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(403)
}
