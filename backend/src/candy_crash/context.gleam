// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import candy_crash/arango/client.{type Connection as ArangoConnection}
import candy_crash/verisim/client.{type Connection as VerisimConnection}
import candy_crash/models/user.{type User}

pub type Context {
  Context(
    db: ArangoConnection,
    verisim: VerisimConnection,
    secret_key_base: String,
  )
}

pub type AuthContext {
  AuthContext(
    db: ArangoConnection,
    verisim: VerisimConnection,
    secret_key_base: String,
    current_user: User,
  )
}
