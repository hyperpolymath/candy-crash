// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result

pub type Config {
  Config(
    url: String,
    database: String,
  )
}

pub type Connection {
  Connection(config: Config)
}

pub type VerisimError {
  ConnectionError(String)
  QueryError(code: Int, message: String)
  DecodeError(List(DecodeError))
  HttpError(String)
}

pub type EventResponse {
  EventResponse(id: String, status: String)
}

/// Connect to VerisimDB
pub fn connect(config: Config) -> Result(Connection, VerisimError) {
  Ok(Connection(config: config))
}

/// Store an event in VerisimDB
pub fn store_event(
  conn: Connection,
  collection: String,
  event: Json,
) -> Result(EventResponse, VerisimError) {
  let body = json.object([
    #("collection", json.string(collection)),
    #("data", event),
  ])

  let url = conn.config.url <> "/api/v1/events"

  case make_request(conn, http.Post, url, Some(json.to_string(body))) {
    Ok(resp) -> {
      case resp.status {
        200 | 201 -> {
          let decoder = dynamic.decode2(
            EventResponse,
            dynamic.field("id", dynamic.string),
            dynamic.field("status", dynamic.string),
          )
          case json.decode(resp.body, decoder) {
            Ok(res) -> Ok(res)
            Error(errs) -> Error(DecodeError(errs))
          }
        }
        _ -> Error(QueryError(resp.status, resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Query events as of a specific time
pub fn query_as_of(
  conn: Connection,
  collection: String,
  as_of: String,
  decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(List(a), VerisimError) {
  let url = conn.config.url 
    <> "/api/v1/query/" <> collection 
    <> "?as_of=" <> as_of

  case make_request(conn, http.Get, url, None) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          case json.decode(resp.body, dynamic.list(decoder)) {
            Ok(results) -> Ok(results)
            Error(errs) -> Error(DecodeError(errs))
          }
        }
        _ -> Error(QueryError(resp.status, resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

// Internal helpers

fn make_request(
  _conn: Connection,
  method: http.Method,
  url: String,
  body: Option(String),
) -> Result(Response(String), VerisimError) {
  let assert Ok(base_req) = request.to(url)
  let req = request.set_method(base_req, method)
    |> request.set_header("Content-Type", "application/json")

  let req = case body {
    Some(b) -> request.set_body(req, b)
    None -> req
  }

  case httpc.send(req) {
    Ok(resp) -> Ok(resp)
    Error(_) -> Error(HttpError("Request failed to " <> url))
  }
}
