// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import birl
import gleam/bit_array
import gleam/crypto
import gleam/dynamic
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import candy_crash/arango/client.{type ArangoError, type Connection}
import candy_crash/models/user.{type User, User}

pub type AuthError {
  InvalidCredentials
  UserNotFound
  UserExists
  TokenError(String)
  DatabaseError(ArangoError)
}

/// Hash a password using SHA-256
pub fn hash_password(password: String) -> String {
  crypto.hash(crypto.Sha256, bit_array.from_string(password))
  |> bit_array.base64_encode(True)
}

/// Verify a password against a hash
pub fn verify_password(password: String, hash: String) -> Bool {
  hash_password(password) == hash
}

/// Create a JWT-like token (simplified for demo - use proper JWT in production)
pub fn create_token(user_key: String, secret: String) -> String {
  let now = birl.now() |> birl.to_unix
  let exp = now + 86400  // 24 hours
  let payload = user_key <> ":" <> int.to_string(exp)
  let signature = sign(payload, secret)
  payload <> "." <> signature
}

/// Verify and decode a token
pub fn verify_token(token: String, secret: String) -> Result(String, AuthError) {
  case string.split(token, ".") {
    [payload, signature] -> {
      case sign(payload, secret) == signature {
        True -> {
          case string.split(payload, ":") {
            [user_key, exp_str] -> {
              case int.parse(exp_str) {
                Ok(exp) -> {
                  let now = birl.now() |> birl.to_unix
                  case exp > now {
                    True -> Ok(user_key)
                    False -> Error(TokenError("Token expired"))
                  }
                }
                Error(_) -> Error(TokenError("Invalid token format"))
              }
            }
            _ -> Error(TokenError("Invalid token format"))
          }
        }
        False -> Error(TokenError("Invalid signature"))
      }
    }
    _ -> Error(TokenError("Invalid token format"))
  }
}

fn sign(payload: String, secret: String) -> String {
  crypto.hash(crypto.Sha256, bit_array.from_string(payload <> secret))
  |> bit_array.base64_encode(True)
}

/// Register a new user
pub fn register(
  db: Connection,
  email: String,
  password: String,
  role: user.Role,
) -> Result(User, AuthError) {
  // Check if user exists
  case find_user_by_email(db, email) {
    Ok(Some(_)) -> Error(UserExists)
    Ok(None) -> {
      let hashed = hash_password(password)
      let new_user = user.new_user(email, hashed, role)
      case client.insert_document(db, "users", user.to_json(new_user), user.decoder) {
        Ok(u) -> Ok(u)
        Error(e) -> Error(DatabaseError(e))
      }
    }
    Error(e) -> Error(DatabaseError(e))
  }
}

/// Authenticate a user
pub fn login(
  db: Connection,
  email: String,
  password: String,
) -> Result(User, AuthError) {
  case find_user_by_email(db, email) {
    Ok(Some(u)) -> {
      case verify_password(password, u.encrypted_password) {
        True -> Ok(u)
        False -> Error(InvalidCredentials)
      }
    }
    Ok(None) -> Error(InvalidCredentials)
    Error(e) -> Error(DatabaseError(e))
  }
}

/// Find user by email
pub fn find_user_by_email(
  db: Connection,
  email: String,
) -> Result(Option(User), ArangoError) {
  let query = "FOR u IN users FILTER u.email == @email LIMIT 1 RETURN u"
  let bind_vars = [#("email", json.string(email))]

  case client.query(db, query, bind_vars, user.decoder) {
    Ok(result) -> {
      case result.result {
        [u, ..] -> Ok(Some(u))
        [] -> Ok(None)
      }
    }
    Error(e) -> Error(e)
  }
}

/// Get user by key
pub fn get_user_by_key(
  db: Connection,
  key: String,
) -> Result(Option(User), ArangoError) {
  client.get_document(db, "users", key, user.decoder)
}

/// Update user password
pub fn update_password(
  db: Connection,
  user_key: String,
  new_password: String,
) -> Result(User, ArangoError) {
  let hashed = hash_password(new_password)
  let update = json.object([
    #("encrypted_password", json.string(hashed)),
    #("reset_password_token", json.null()),
    #("reset_password_sent_at", json.null()),
  ])
  client.update_document(db, "users", user_key, update, user.decoder)
}

/// Generate password reset token
pub fn generate_reset_token(
  db: Connection,
  user_key: String,
) -> Result(String, ArangoError) {
  let token = crypto.strong_random_bytes(32)
    |> bit_array.base64_url_encode(False)
  let now = birl.now() |> birl.to_iso8601

  let update = json.object([
    #("reset_password_token", json.string(token)),
    #("reset_password_sent_at", json.string(now)),
  ])

  case client.update_document(db, "users", user_key, update, user.decoder) {
    Ok(_) -> Ok(token)
    Error(e) -> Error(e)
  }
}
