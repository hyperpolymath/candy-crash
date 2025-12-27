// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import candy_crash/arango/client.{type Connection}
import candy_crash/models/user.{type User}

pub type Context {
  Context(
    db: Connection,
    secret_key_base: String,
  )
}

pub type AuthContext {
  AuthContext(
    db: Connection,
    secret_key_base: String,
    current_user: User,
  )
}
