// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri

pub type Config {
  Config(
    url: String,
    database: String,
    username: String,
    password: String,
  )
}

pub type Connection {
  Connection(
    config: Config,
    auth_token: Option(String),
  )
}

pub type ArangoError {
  ConnectionError(String)
  AuthenticationError(String)
  QueryError(code: Int, message: String)
  DocumentError(code: Int, message: String)
  DecodeError(List(DecodeError))
  HttpError(String)
}

pub type QueryResult(a) {
  QueryResult(
    result: List(a),
    has_more: Bool,
    cursor_id: Option(String),
  )
}

/// Connect to ArangoDB and authenticate
pub fn connect(config: Config) -> Result(Connection, ArangoError) {
  let conn = Connection(config: config, auth_token: None)
  authenticate(conn)
}

fn authenticate(conn: Connection) -> Result(Connection, ArangoError) {
  let body = json.object([
    #("username", json.string(conn.config.username)),
    #("password", json.string(conn.config.password)),
  ])

  let url = conn.config.url <> "/_open/auth"

  case make_request(conn, http.Post, url, Some(json.to_string(body))) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          let decoder = dynamic.field("jwt", dynamic.string)
          case json.decode(resp.body, decoder) {
            Ok(token) -> Ok(Connection(..conn, auth_token: Some(token)))
            Error(errs) -> Error(DecodeError(errs))
          }
        }
        401 -> Error(AuthenticationError("Invalid credentials"))
        _ -> Error(AuthenticationError("Authentication failed: " <> resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Execute an AQL query
pub fn query(
  conn: Connection,
  aql: String,
  bind_vars: List(#(String, Json)),
  decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(QueryResult(a), ArangoError) {
  let body = json.object([
    #("query", json.string(aql)),
    #("bindVars", json.object(bind_vars)),
  ])

  let url = conn.config.url <> "/_db/" <> conn.config.database <> "/_api/cursor"

  case make_auth_request(conn, http.Post, url, Some(json.to_string(body))) {
    Ok(resp) -> parse_query_response(resp, decoder)
    Error(e) -> Error(e)
  }
}

/// Get a single document by key
pub fn get_document(
  conn: Connection,
  collection: String,
  key: String,
  decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(Option(a), ArangoError) {
  let url = conn.config.url
    <> "/_db/" <> conn.config.database
    <> "/_api/document/" <> collection <> "/" <> key

  case make_auth_request(conn, http.Get, url, None) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          case json.decode(resp.body, decoder) {
            Ok(doc) -> Ok(Some(doc))
            Error(errs) -> Error(DecodeError(errs))
          }
        }
        404 -> Ok(None)
        _ -> Error(DocumentError(resp.status, resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Insert a new document
pub fn insert_document(
  conn: Connection,
  collection: String,
  document: Json,
  decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(a, ArangoError) {
  let url = conn.config.url
    <> "/_db/" <> conn.config.database
    <> "/_api/document/" <> collection <> "?returnNew=true"

  case make_auth_request(conn, http.Post, url, Some(json.to_string(document))) {
    Ok(resp) -> {
      case resp.status {
        201 | 202 -> {
          let new_decoder = dynamic.field("new", decoder)
          case json.decode(resp.body, new_decoder) {
            Ok(doc) -> Ok(doc)
            Error(errs) -> Error(DecodeError(errs))
          }
        }
        _ -> Error(DocumentError(resp.status, resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Update a document
pub fn update_document(
  conn: Connection,
  collection: String,
  key: String,
  document: Json,
  decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(a, ArangoError) {
  let url = conn.config.url
    <> "/_db/" <> conn.config.database
    <> "/_api/document/" <> collection <> "/" <> key <> "?returnNew=true"

  case make_auth_request(conn, http.Patch, url, Some(json.to_string(document))) {
    Ok(resp) -> {
      case resp.status {
        200 | 201 | 202 -> {
          let new_decoder = dynamic.field("new", decoder)
          case json.decode(resp.body, new_decoder) {
            Ok(doc) -> Ok(doc)
            Error(errs) -> Error(DecodeError(errs))
          }
        }
        _ -> Error(DocumentError(resp.status, resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Delete a document
pub fn delete_document(
  conn: Connection,
  collection: String,
  key: String,
) -> Result(Nil, ArangoError) {
  let url = conn.config.url
    <> "/_db/" <> conn.config.database
    <> "/_api/document/" <> collection <> "/" <> key

  case make_auth_request(conn, http.Delete, url, None) {
    Ok(resp) -> {
      case resp.status {
        200 | 202 -> Ok(Nil)
        404 -> Error(DocumentError(404, "Document not found"))
        _ -> Error(DocumentError(resp.status, resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Create an edge in a graph
pub fn insert_edge(
  conn: Connection,
  collection: String,
  from: String,
  to: String,
  data: List(#(String, Json)),
) -> Result(String, ArangoError) {
  let document = json.object([
    #("_from", json.string(from)),
    #("_to", json.string(to)),
    ..data
  ])

  let url = conn.config.url
    <> "/_db/" <> conn.config.database
    <> "/_api/document/" <> collection

  case make_auth_request(conn, http.Post, url, Some(json.to_string(document))) {
    Ok(resp) -> {
      case resp.status {
        201 | 202 -> {
          case json.decode(resp.body, dynamic.field("_key", dynamic.string)) {
            Ok(key) -> Ok(key)
            Error(errs) -> Error(DecodeError(errs))
          }
        }
        _ -> Error(DocumentError(resp.status, resp.body))
      }
    }
    Error(e) -> Error(e)
  }
}

// Internal helpers

fn make_request(
  conn: Connection,
  method: http.Method,
  url: String,
  body: Option(String),
) -> Result(Response(String), ArangoError) {
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

fn make_auth_request(
  conn: Connection,
  method: http.Method,
  url: String,
  body: Option(String),
) -> Result(Response(String), ArangoError) {
  case conn.auth_token {
    None -> Error(AuthenticationError("Not authenticated"))
    Some(token) -> {
      let assert Ok(base_req) = request.to(url)
      let req = request.set_method(base_req, method)
        |> request.set_header("Content-Type", "application/json")
        |> request.set_header("Authorization", "bearer " <> token)

      let req = case body {
        Some(b) -> request.set_body(req, b)
        None -> req
      }

      case httpc.send(req) {
        Ok(resp) -> Ok(resp)
        Error(_) -> Error(HttpError("Request failed to " <> url))
      }
    }
  }
}

fn parse_query_response(
  resp: Response(String),
  decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(QueryResult(a), ArangoError) {
  case resp.status {
    200 | 201 -> {
      let result_decoder = dynamic.decode3(
        fn(result, has_more, cursor_id) {
          QueryResult(result: result, has_more: has_more, cursor_id: cursor_id)
        },
        dynamic.field("result", dynamic.list(decoder)),
        dynamic.field("hasMore", dynamic.bool),
        dynamic.optional_field("id", dynamic.string),
      )
      case json.decode(resp.body, result_decoder) {
        Ok(qr) -> Ok(qr)
        Error(errs) -> Error(DecodeError(errs))
      }
    }
    _ -> {
      let error_decoder = dynamic.decode2(
        fn(code, msg) { #(code, msg) },
        dynamic.field("errorNum", dynamic.int),
        dynamic.field("errorMessage", dynamic.string),
      )
      case json.decode(resp.body, error_decoder) {
        Ok(#(code, msg)) -> Error(QueryError(code, msg))
        Error(_) -> Error(QueryError(resp.status, resp.body))
      }
    }
  }
}
