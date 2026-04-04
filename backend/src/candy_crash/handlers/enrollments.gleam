// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import birl
import gleam/dynamic
import gleam/http
import gleam/json
import gleam/option.{type Option, None, Some}
import wisp.{type Request, type Response}

import candy_crash/arango/client
import candy_crash/context.{type AuthContext}
import candy_crash/models/enrollment.{type Enrollment}

pub fn index(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      let query = "
        FOR e IN enrollments
        FILTER e.user_key == @user_key
        SORT e.enrolled_at DESC
        LET course = DOCUMENT('courses', e.course_key)
        LET category = DOCUMENT('categories', course.category_key)
        RETURN MERGE(e, {
          course: MERGE(course, { category: category })
        })
      "

      case client.query(auth_ctx.db, query, [
        #("user_key", json.string(user_key)),
      ], enrollment.decoder) {
        Ok(result) -> {
          json.object([
            #("enrollments", json.array(result.result, enrollment_to_json)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch enrollments", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn enroll(req: Request, auth_ctx: AuthContext, course_id: String) -> Response {
  case req.method {
    http.Post -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let now = birl.now() |> birl.to_iso8601

      // Check if already enrolled
      let check_query = "
        FOR e IN enrollments
        FILTER e.user_key == @user_key AND e.course_key == @course_id
        RETURN e
      "

      case client.query(auth_ctx.db, check_query, [
        #("user_key", json.string(user_key)),
        #("course_id", json.string(course_id)),
      ], enrollment.decoder) {
        Ok(result) -> {
          case result.result {
            [existing, ..] -> {
              // Already enrolled
              json.object([
                #("message", json.string("Already enrolled")),
                #("enrollment", enrollment_to_json(existing)),
              ])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            [] -> {
              // Check if course exists and is published
              let course_query = "
                FOR c IN courses
                FILTER c._key == @course_id AND c.published == true
                RETURN c
              "

              case client.query(auth_ctx.db, course_query, [
                #("course_id", json.string(course_id)),
              ], dynamic.dynamic) {
                Ok(course_result) -> {
                  case course_result.result {
                    [_, ..] -> {
                      // Create enrollment
                      let new_enrollment = enrollment.new_enrollment(
                        user_key,
                        course_id,
                        now,
                      )

                      case client.insert_document(
                        auth_ctx.db,
                        "enrollments",
                        enrollment.to_json(new_enrollment),
                        enrollment.decoder,
                      ) {
                        Ok(e) -> {
                          json.object([
                            #("message", json.string("Enrolled successfully")),
                            #("enrollment", enrollment_to_json(e)),
                          ])
                          |> json.to_string_builder
                          |> wisp.json_response(201)
                        }
                        Error(_) -> error_response("Failed to enroll", 500)
                      }
                    }
                    [] -> error_response("Course not found", 404)
                  }
                }
                Error(_) -> error_response("Failed to verify course", 500)
              }
            }
          }
        }
        Error(_) -> error_response("Failed to check enrollment", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

fn enrollment_to_json(e: Enrollment) -> json.Json {
  json.object([
    #("key", json.string(e.key |> option.unwrap(""))),
    #("user_key", json.string(e.user_key)),
    #("course_key", json.string(e.course_key)),
    #("enrolled_at", json.string(e.enrolled_at)),
    #("completed_at", case e.completed_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("progress", json.int(e.progress)),
    #("status", json.string(enrollment.status_to_string(e.status))),
  ])
}

fn error_response(message: String, status: Int) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(status)
}
