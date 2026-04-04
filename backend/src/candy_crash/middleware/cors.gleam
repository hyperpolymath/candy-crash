// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/http
import wisp.{type Request, type Response}

pub fn middleware(req: Request, handler: fn(Request) -> Response) -> Response {
  case req.method {
    http.Options -> preflight_response()
    _ -> {
      let resp = handler(req)
      add_cors_headers(resp)
    }
  }
}

fn preflight_response() -> Response {
  wisp.response(204)
  |> add_cors_headers
}

fn add_cors_headers(resp: Response) -> Response {
  resp
  |> wisp.set_header("Access-Control-Allow-Origin", "*")
  |> wisp.set_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
  |> wisp.set_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
  |> wisp.set_header("Access-Control-Max-Age", "86400")
}
