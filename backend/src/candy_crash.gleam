// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import argv
import envoy
import gleam/erlang/process
import gleam/io
import gleam/result
import mist
import wisp
import wisp/wisp_mist

import candy_crash/router
import candy_crash/arango/client as arango
import candy_crash/context.{Context}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(arango_url) = envoy.get("ARANGO_URL")
    |> result.replace_error("ARANGO_URL not set")
  let assert Ok(arango_db) = envoy.get("ARANGO_DATABASE")
    |> result.replace_error("ARANGO_DATABASE not set")
  let arango_user = envoy.get("ARANGO_USER") |> result.unwrap("root")
  let arango_pass = envoy.get("ARANGO_PASSWORD") |> result.unwrap("")

  let assert Ok(secret_key_base) = envoy.get("SECRET_KEY_BASE")
    |> result.replace_error("SECRET_KEY_BASE not set")

  let port = case envoy.get("PORT") {
    Ok(p) -> {
      let assert Ok(n) = gleam/int.parse(p)
      n
    }
    Error(_) -> 4000
  }

  let arango_config = arango.Config(
    url: arango_url,
    database: arango_db,
    username: arango_user,
    password: arango_pass,
  )

  let assert Ok(db) = arango.connect(arango_config)

  let ctx = Context(
    db: db,
    secret_key_base: secret_key_base,
  )

  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  io.println("🍬 Candy Crash started on port " <> int.to_string(port))

  process.sleep_forever()
}
