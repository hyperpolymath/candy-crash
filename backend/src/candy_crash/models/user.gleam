// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type Role {
  Student
  Instructor
  Admin
}

pub type User {
  User(
    key: Option(String),
    email: String,
    encrypted_password: String,
    role: Role,
    reset_password_token: Option(String),
    reset_password_sent_at: Option(String),
    remember_created_at: Option(String),
    created_at: Option(String),
    updated_at: Option(String),
  )
}

pub type Profile {
  Profile(
    key: Option(String),
    user_key: String,
    first_name: Option(String),
    last_name: Option(String),
    phone: Option(String),
    date_of_birth: Option(String),
  )
}

pub fn role_to_string(role: Role) -> String {
  case role {
    Student -> "student"
    Instructor -> "instructor"
    Admin -> "admin"
  }
}

pub fn role_from_string(s: String) -> Role {
  case s {
    "instructor" -> Instructor
    "admin" -> Admin
    _ -> Student
  }
}

pub fn decoder(dyn: Dynamic) -> Result(User, List(DecodeError)) {
  dynamic.decode9(
    User,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("email", dynamic.string),
    dynamic.field("encrypted_password", dynamic.string),
    dynamic.field("role", fn(d) {
      dynamic.string(d)
      |> gleam/result.map(role_from_string)
    }),
    dynamic.optional_field("reset_password_token", dynamic.string),
    dynamic.optional_field("reset_password_sent_at", dynamic.string),
    dynamic.optional_field("remember_created_at", dynamic.string),
    dynamic.optional_field("created_at", dynamic.string),
    dynamic.optional_field("updated_at", dynamic.string),
  )(dyn)
}

pub fn profile_decoder(dyn: Dynamic) -> Result(Profile, List(DecodeError)) {
  dynamic.decode6(
    Profile,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("user_key", dynamic.string),
    dynamic.optional_field("first_name", dynamic.string),
    dynamic.optional_field("last_name", dynamic.string),
    dynamic.optional_field("phone", dynamic.string),
    dynamic.optional_field("date_of_birth", dynamic.string),
  )(dyn)
}

pub fn to_json(user: User) -> Json {
  json.object([
    #("email", json.string(user.email)),
    #("encrypted_password", json.string(user.encrypted_password)),
    #("role", json.string(role_to_string(user.role))),
    #("reset_password_token", case user.reset_password_token {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("reset_password_sent_at", case user.reset_password_sent_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("remember_created_at", case user.remember_created_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
  ])
}

pub fn profile_to_json(profile: Profile) -> Json {
  json.object([
    #("user_key", json.string(profile.user_key)),
    #("first_name", case profile.first_name {
      Some(n) -> json.string(n)
      None -> json.null()
    }),
    #("last_name", case profile.last_name {
      Some(n) -> json.string(n)
      None -> json.null()
    }),
    #("phone", case profile.phone {
      Some(p) -> json.string(p)
      None -> json.null()
    }),
    #("date_of_birth", case profile.date_of_birth {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
  ])
}

pub fn new_user(email: String, encrypted_password: String, role: Role) -> User {
  User(
    key: None,
    email: email,
    encrypted_password: encrypted_password,
    role: role,
    reset_password_token: None,
    reset_password_sent_at: None,
    remember_created_at: None,
    created_at: None,
    updated_at: None,
  )
}

pub fn is_admin(user: User) -> Bool {
  user.role == Admin
}

pub fn is_instructor(user: User) -> Bool {
  user.role == Instructor || user.role == Admin
}

pub fn is_student(user: User) -> Bool {
  user.role == Student
}
