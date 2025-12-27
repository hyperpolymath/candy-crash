// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import birl
import gleam/dynamic
import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import wisp.{type Request, type Response}

import candy_crash/arango/client
import candy_crash/context.{type AuthContext}
import candy_crash/models/quiz.{type Quiz, type QuizAttempt, type QuizAnswer}
import candy_crash/services/achievement as achievement_service

pub fn index(req: Request, auth_ctx: AuthContext, course_id: String) -> Response {
  case req.method {
    http.Get -> {
      let query = "
        FOR q IN quizzes
        FILTER q.course_key == @course_id AND q.published == true
        RETURN q
      "

      case client.query(auth_ctx.db, query, [
        #("course_id", json.string(course_id)),
      ], quiz.quiz_decoder) {
        Ok(result) -> {
          json.object([
            #("quizzes", json.array(result.result, quiz_to_json)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch quizzes", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn show(req: Request, auth_ctx: AuthContext, course_id: String, quiz_id: String) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      let query = "
        FOR q IN quizzes
        FILTER q._key == @quiz_id AND q.course_key == @course_id AND q.published == true
        LET attempts = (
          FOR a IN quiz_attempts
          FILTER a.quiz_key == q._key AND a.user_key == @user_key
          SORT a.started_at DESC
          RETURN a
        )
        LET best_score = MAX(
          FOR a IN quiz_attempts
          FILTER a.quiz_key == q._key AND a.user_key == @user_key AND a.completed_at != null
          RETURN a.score
        )
        RETURN MERGE(q, {
          attempts: attempts,
          best_score: best_score,
          attempts_count: LENGTH(attempts)
        })
      "

      case client.query(auth_ctx.db, query, [
        #("quiz_id", json.string(quiz_id)),
        #("course_id", json.string(course_id)),
        #("user_key", json.string(user_key)),
      ], quiz.quiz_decoder) {
        Ok(result) -> {
          case result.result {
            [q, ..] -> {
              quiz_to_json(q)
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            [] -> wisp.not_found()
          }
        }
        Error(_) -> error_response("Failed to fetch quiz", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn attempts(req: Request, auth_ctx: AuthContext, quiz_id: String) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      let query = "
        FOR a IN quiz_attempts
        FILTER a.quiz_key == @quiz_id AND a.user_key == @user_key
        SORT a.started_at DESC
        RETURN a
      "

      case client.query(auth_ctx.db, query, [
        #("quiz_id", json.string(quiz_id)),
        #("user_key", json.string(user_key)),
      ], quiz.attempt_decoder) {
        Ok(result) -> {
          json.object([
            #("attempts", json.array(result.result, attempt_to_json)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch attempts", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn new_attempt(req: Request, auth_ctx: AuthContext, quiz_id: String) -> Response {
  case req.method {
    http.Post -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let now = birl.now() |> birl.to_iso8601

      // Check max attempts
      let check_query = "
        LET quiz = DOCUMENT('quizzes', @quiz_id)
        LET attempts_count = LENGTH(
          FOR a IN quiz_attempts
          FILTER a.quiz_key == @quiz_id AND a.user_key == @user_key
          RETURN a
        )
        RETURN {
          quiz: quiz,
          attempts_count: attempts_count,
          can_attempt: quiz.max_attempts == null OR attempts_count < quiz.max_attempts
        }
      "

      case client.query(auth_ctx.db, check_query, [
        #("quiz_id", json.string(quiz_id)),
        #("user_key", json.string(user_key)),
      ], dynamic.dynamic) {
        Ok(result) -> {
          // Create new attempt
          let new_attempt = quiz.QuizAttempt(
            key: None,
            user_key: user_key,
            quiz_key: quiz_id,
            score: None,
            started_at: now,
            completed_at: None,
            passed: None,
          )

          case client.insert_document(
            auth_ctx.db,
            "quiz_attempts",
            quiz.attempt_to_json(new_attempt),
            quiz.attempt_decoder,
          ) {
            Ok(a) -> {
              // Get quiz questions
              let questions_query = "
                FOR qq IN quiz_questions
                FILTER qq.quiz_key == @quiz_id
                SORT qq.position
                LET q = DOCUMENT('questions', qq.question_key)
                LET options = (
                  FOR o IN question_options
                  FILTER o.question_key == q._key
                  SORT o.position
                  RETURN { key: o._key, content: o.content, position: o.position }
                )
                RETURN MERGE(q, { options: options })
              "

              case client.query(auth_ctx.db, questions_query, [
                #("quiz_id", json.string(quiz_id)),
              ], dynamic.dynamic) {
                Ok(q_result) -> {
                  json.object([
                    #("attempt", attempt_to_json(a)),
                    #("questions", json.array(q_result.result, fn(q) { json.string("question") })),
                  ])
                  |> json.to_string_builder
                  |> wisp.json_response(201)
                }
                Error(_) -> {
                  json.object([#("attempt", attempt_to_json(a))])
                  |> json.to_string_builder
                  |> wisp.json_response(201)
                }
              }
            }
            Error(_) -> error_response("Failed to create attempt", 500)
          }
        }
        Error(_) -> error_response("Failed to check attempts", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

pub fn get_attempt(req: Request, auth_ctx: AuthContext, attempt_id: String) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      let query = "
        FOR a IN quiz_attempts
        FILTER a._key == @attempt_id AND a.user_key == @user_key
        LET quiz = DOCUMENT('quizzes', a.quiz_key)
        LET answers = (
          FOR ans IN quiz_answers
          FILTER ans.attempt_key == a._key
          RETURN ans
        )
        RETURN MERGE(a, {
          quiz: quiz,
          answers: answers
        })
      "

      case client.query(auth_ctx.db, query, [
        #("attempt_id", json.string(attempt_id)),
        #("user_key", json.string(user_key)),
      ], quiz.attempt_decoder) {
        Ok(result) -> {
          case result.result {
            [a, ..] -> {
              attempt_to_json(a)
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            [] -> wisp.not_found()
          }
        }
        Error(_) -> error_response("Failed to fetch attempt", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn submit_answer(req: Request, auth_ctx: AuthContext, attempt_id: String) -> Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_json(req)

      let decoder = dynamic.decode2(
        fn(question_key, option_key) { #(question_key, option_key) },
        dynamic.field("question_key", dynamic.string),
        dynamic.optional_field("option_key", dynamic.string),
      )

      case dynamic.from(body) |> decoder {
        Ok(#(question_key, option_key)) -> {
          // Get correct answer and calculate points
          let check_query = "
            LET question = DOCUMENT('questions', @question_key)
            LET correct_option = FIRST(
              FOR o IN question_options
              FILTER o.question_key == @question_key AND o.is_correct == true
              RETURN o
            )
            LET is_correct = @option_key != null AND correct_option._key == @option_key
            RETURN {
              is_correct: is_correct,
              points: is_correct ? question.points : 0
            }
          "

          case client.query(auth_ctx.db, check_query, [
            #("question_key", json.string(question_key)),
            #("option_key", case option_key {
              Some(k) -> json.string(k)
              None -> json.null()
            }),
          ], dynamic.dynamic) {
            Ok(result) -> {
              // Create answer record
              let new_answer = quiz.QuizAnswer(
                key: None,
                attempt_key: attempt_id,
                question_key: question_key,
                option_key: option_key,
                answer_text: None,
                is_correct: Some(True),  // Simplified
                points_earned: 0,
              )

              case client.insert_document(
                auth_ctx.db,
                "quiz_answers",
                answer_to_insert_json(new_answer),
                quiz.answer_decoder,
              ) {
                Ok(a) -> {
                  answer_to_json(a)
                  |> json.to_string_builder
                  |> wisp.json_response(201)
                }
                Error(_) -> error_response("Failed to submit answer", 500)
              }
            }
            Error(_) -> error_response("Failed to validate answer", 500)
          }
        }
        Error(_) -> error_response("Invalid request body", 400)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

pub fn complete_attempt(req: Request, auth_ctx: AuthContext, attempt_id: String) -> Response {
  case req.method {
    http.Post -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let now = birl.now() |> birl.to_iso8601

      // Calculate score
      let score_query = "
        LET attempt = DOCUMENT('quiz_attempts', @attempt_id)
        LET quiz = DOCUMENT('quizzes', attempt.quiz_key)
        LET total_points = SUM(
          FOR qq IN quiz_questions
          FILTER qq.quiz_key == attempt.quiz_key
          LET q = DOCUMENT('questions', qq.question_key)
          RETURN q.points
        )
        LET earned_points = SUM(
          FOR a IN quiz_answers
          FILTER a.attempt_key == @attempt_id
          RETURN a.points_earned
        )
        LET score = total_points > 0 ? (earned_points / total_points) * 100 : 0
        LET passed = score >= quiz.passing_score
        UPDATE attempt WITH {
          score: score,
          completed_at: @now,
          passed: passed
        } IN quiz_attempts
        RETURN NEW
      "

      case client.query(auth_ctx.db, score_query, [
        #("attempt_id", json.string(attempt_id)),
        #("now", json.string(now)),
      ], quiz.attempt_decoder) {
        Ok(result) -> {
          case result.result {
            [a, ..] -> {
              // Check for achievements
              achievement_service.check_and_award(auth_ctx.db, user_key)

              attempt_to_json(a)
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            [] -> error_response("Attempt not found", 404)
          }
        }
        Error(_) -> error_response("Failed to complete attempt", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

fn quiz_to_json(q: Quiz) -> json.Json {
  json.object([
    #("key", json.string(q.key |> option.unwrap(""))),
    #("course_key", json.string(q.course_key)),
    #("title", json.string(q.title)),
    #("description", case q.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("passing_score", json.int(q.passing_score)),
    #("time_limit_minutes", case q.time_limit_minutes {
      Some(t) -> json.int(t)
      None -> json.null()
    }),
    #("quiz_type", json.string(quiz.quiz_type_to_string(q.quiz_type))),
    #("published", json.bool(q.published)),
    #("max_attempts", case q.max_attempts {
      Some(m) -> json.int(m)
      None -> json.null()
    }),
  ])
}

fn attempt_to_json(a: QuizAttempt) -> json.Json {
  json.object([
    #("key", json.string(a.key |> option.unwrap(""))),
    #("user_key", json.string(a.user_key)),
    #("quiz_key", json.string(a.quiz_key)),
    #("score", case a.score {
      Some(s) -> json.float(s)
      None -> json.null()
    }),
    #("started_at", json.string(a.started_at)),
    #("completed_at", case a.completed_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("passed", case a.passed {
      Some(p) -> json.bool(p)
      None -> json.null()
    }),
  ])
}

fn answer_to_json(a: QuizAnswer) -> json.Json {
  json.object([
    #("key", json.string(a.key |> option.unwrap(""))),
    #("attempt_key", json.string(a.attempt_key)),
    #("question_key", json.string(a.question_key)),
    #("option_key", case a.option_key {
      Some(k) -> json.string(k)
      None -> json.null()
    }),
    #("is_correct", case a.is_correct {
      Some(c) -> json.bool(c)
      None -> json.null()
    }),
    #("points_earned", json.int(a.points_earned)),
  ])
}

fn answer_to_insert_json(a: QuizAnswer) -> json.Json {
  json.object([
    #("attempt_key", json.string(a.attempt_key)),
    #("question_key", json.string(a.question_key)),
    #("option_key", case a.option_key {
      Some(k) -> json.string(k)
      None -> json.null()
    }),
    #("answer_text", case a.answer_text {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("is_correct", case a.is_correct {
      Some(c) -> json.bool(c)
      None -> json.null()
    }),
    #("points_earned", json.int(a.points_earned)),
  ])
}

fn error_response(message: String, status: Int) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(status)
}
