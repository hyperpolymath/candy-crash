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
import candy_crash/models/lesson.{type Lesson, type LessonProgress}
import candy_crash/services/achievement as achievement_service

pub fn index(req: Request, auth_ctx: AuthContext, course_id: String) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      // Verify enrollment first
      case verify_enrollment(auth_ctx, user_key, course_id) {
        True -> {
          let query = "
            FOR m IN course_modules
            FILTER m.course_key == @course_id AND m.published == true
            SORT m.position
            LET lessons = (
              FOR l IN lessons
              FILTER l.module_key == m._key AND l.published == true
              SORT l.position
              LET progress = FIRST(
                FOR p IN lesson_progress
                FILTER p.user_key == @user_key AND p.lesson_key == l._key
                RETURN p
              )
              RETURN MERGE(l, { progress: progress })
            )
            RETURN { module: m, lessons: lessons }
          "

          case client.query(auth_ctx.db, query, [
            #("course_id", json.string(course_id)),
            #("user_key", json.string(user_key)),
          ], dynamic.dynamic) {
            Ok(result) -> {
              json.object([
                #("modules", json.array(result.result, fn(m) { json.string("module") })),
              ])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            Error(_) -> error_response("Failed to fetch lessons", 500)
          }
        }
        False -> error_response("Not enrolled in this course", 403)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn show(req: Request, auth_ctx: AuthContext, course_id: String, lesson_id: String) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      case verify_enrollment(auth_ctx, user_key, course_id) {
        True -> {
          let query = "
            FOR l IN lessons
            FILTER l._key == @lesson_id AND l.published == true
            LET module = DOCUMENT('course_modules', l.module_key)
            FILTER module.course_key == @course_id
            LET progress = FIRST(
              FOR p IN lesson_progress
              FILTER p.user_key == @user_key AND p.lesson_key == l._key
              RETURN p
            )
            LET prev = FIRST(
              FOR pl IN lessons
              FILTER pl.module_key == l.module_key AND pl.position < l.position AND pl.published == true
              SORT pl.position DESC
              LIMIT 1
              RETURN pl._key
            )
            LET next = FIRST(
              FOR nl IN lessons
              FILTER nl.module_key == l.module_key AND nl.position > l.position AND nl.published == true
              SORT nl.position ASC
              LIMIT 1
              RETURN nl._key
            )
            RETURN MERGE(l, {
              progress: progress,
              prev_lesson: prev,
              next_lesson: next
            })
          "

          case client.query(auth_ctx.db, query, [
            #("lesson_id", json.string(lesson_id)),
            #("course_id", json.string(course_id)),
            #("user_key", json.string(user_key)),
          ], lesson.decoder) {
            Ok(result) -> {
              case result.result {
                [l, ..] -> {
                  lesson_to_json(l)
                  |> json.to_string_builder
                  |> wisp.json_response(200)
                }
                [] -> wisp.not_found()
              }
            }
            Error(_) -> error_response("Failed to fetch lesson", 500)
          }
        }
        False -> error_response("Not enrolled in this course", 403)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn complete(req: Request, auth_ctx: AuthContext, course_id: String, lesson_id: String) -> Response {
  case req.method {
    http.Post -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let now = birl.now() |> birl.to_iso8601

      case verify_enrollment(auth_ctx, user_key, course_id) {
        True -> {
          // Check if progress already exists
          let check_query = "
            FOR p IN lesson_progress
            FILTER p.user_key == @user_key AND p.lesson_key == @lesson_id
            RETURN p
          "

          case client.query(auth_ctx.db, check_query, [
            #("user_key", json.string(user_key)),
            #("lesson_id", json.string(lesson_id)),
          ], lesson.progress_decoder) {
            Ok(result) -> {
              case result.result {
                [existing, ..] -> {
                  // Update existing progress
                  let update = json.object([
                    #("completed", json.bool(True)),
                    #("completed_at", json.string(now)),
                  ])
                  case client.update_document(
                    auth_ctx.db,
                    "lesson_progress",
                    existing.key |> option.unwrap(""),
                    update,
                    lesson.progress_decoder,
                  ) {
                    Ok(p) -> {
                      // Update enrollment progress and check achievements
                      update_enrollment_progress(auth_ctx, user_key, course_id)
                      achievement_service.check_and_award(auth_ctx.db, user_key)

                      progress_to_json(p)
                      |> json.to_string_builder
                      |> wisp.json_response(200)
                    }
                    Error(_) -> error_response("Failed to update progress", 500)
                  }
                }
                [] -> {
                  // Create new progress
                  let new_progress = lesson.LessonProgress(
                    key: None,
                    user_key: user_key,
                    lesson_key: lesson_id,
                    completed: True,
                    completed_at: Some(now),
                    time_spent_minutes: 0,
                  )

                  case client.insert_document(
                    auth_ctx.db,
                    "lesson_progress",
                    lesson.progress_to_json(new_progress),
                    lesson.progress_decoder,
                  ) {
                    Ok(p) -> {
                      // Update enrollment progress and check achievements
                      update_enrollment_progress(auth_ctx, user_key, course_id)
                      achievement_service.check_and_award(auth_ctx.db, user_key)

                      progress_to_json(p)
                      |> json.to_string_builder
                      |> wisp.json_response(201)
                    }
                    Error(_) -> error_response("Failed to create progress", 500)
                  }
                }
              }
            }
            Error(_) -> error_response("Failed to check progress", 500)
          }
        }
        False -> error_response("Not enrolled in this course", 403)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

fn verify_enrollment(auth_ctx: AuthContext, user_key: String, course_id: String) -> Bool {
  let query = "
    FOR e IN enrollments
    FILTER e.user_key == @user_key AND e.course_key == @course_id AND e.status == 'active'
    RETURN e._key
  "

  case client.query(auth_ctx.db, query, [
    #("user_key", json.string(user_key)),
    #("course_id", json.string(course_id)),
  ], dynamic.string) {
    Ok(result) -> {
      case result.result {
        [_, ..] -> True
        [] -> False
      }
    }
    Error(_) -> False
  }
}

fn update_enrollment_progress(auth_ctx: AuthContext, user_key: String, course_id: String) -> Nil {
  // Calculate progress percentage
  let query = "
    LET total_lessons = LENGTH(
      FOR m IN course_modules
      FILTER m.course_key == @course_id AND m.published == true
      FOR l IN lessons
      FILTER l.module_key == m._key AND l.published == true
      RETURN l
    )
    LET completed_lessons = LENGTH(
      FOR m IN course_modules
      FILTER m.course_key == @course_id AND m.published == true
      FOR l IN lessons
      FILTER l.module_key == m._key AND l.published == true
      FOR p IN lesson_progress
      FILTER p.lesson_key == l._key AND p.user_key == @user_key AND p.completed == true
      RETURN p
    )
    FOR e IN enrollments
    FILTER e.user_key == @user_key AND e.course_key == @course_id
    UPDATE e WITH {
      progress: total_lessons > 0 ? FLOOR((completed_lessons / total_lessons) * 100) : 0
    } IN enrollments
    RETURN NEW
  "

  let _ = client.query(auth_ctx.db, query, [
    #("user_key", json.string(user_key)),
    #("course_id", json.string(course_id)),
  ], dynamic.dynamic)

  Nil
}

fn lesson_to_json(l: Lesson) -> json.Json {
  json.object([
    #("key", json.string(l.key |> option.unwrap(""))),
    #("module_key", json.string(l.module_key)),
    #("title", json.string(l.title)),
    #("content", case l.content {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("lesson_type", json.string(lesson.lesson_type_to_string(l.lesson_type))),
    #("position", json.int(l.position)),
    #("duration_minutes", json.int(l.duration_minutes)),
    #("published", json.bool(l.published)),
    #("slug", json.string(l.slug)),
    #("video_url", case l.video_url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

fn progress_to_json(p: LessonProgress) -> json.Json {
  json.object([
    #("key", json.string(p.key |> option.unwrap(""))),
    #("user_key", json.string(p.user_key)),
    #("lesson_key", json.string(p.lesson_key)),
    #("completed", json.bool(p.completed)),
    #("completed_at", case p.completed_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("time_spent_minutes", json.int(p.time_spent_minutes)),
  ])
}

fn error_response(message: String, status: Int) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(status)
}
