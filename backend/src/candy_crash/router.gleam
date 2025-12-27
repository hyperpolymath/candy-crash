// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/http
import gleam/json
import gleam/string
import wisp.{type Request, type Response}

import candy_crash/context.{type Context}
import candy_crash/handlers/auth as auth_handler
import candy_crash/handlers/courses as courses_handler
import candy_crash/handlers/lessons as lessons_handler
import candy_crash/handlers/quizzes as quizzes_handler
import candy_crash/handlers/enrollments as enrollments_handler
import candy_crash/handlers/dashboard as dashboard_handler
import candy_crash/handlers/achievements as achievements_handler
import candy_crash/handlers/training as training_handler
import candy_crash/middleware/auth as auth_middleware
import candy_crash/middleware/cors

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- cors.middleware(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  case wisp.path_segments(req) {
    // Health check
    ["health"] -> health_check()

    // Authentication
    ["api", "auth", "register"] -> auth_handler.register(req, ctx)
    ["api", "auth", "login"] -> auth_handler.login(req, ctx)
    ["api", "auth", "logout"] -> auth_handler.logout(req, ctx)
    ["api", "auth", "me"] -> auth_handler.me(req, ctx)
    ["api", "auth", "forgot-password"] -> auth_handler.forgot_password(req, ctx)
    ["api", "auth", "reset-password"] -> auth_handler.reset_password(req, ctx)

    // Public courses
    ["api", "courses"] -> courses_handler.index(req, ctx)
    ["api", "courses", id] -> courses_handler.show(req, ctx, id)
    ["api", "categories"] -> courses_handler.categories(req, ctx)

    // Protected routes - require authentication
    ["api", "enrollments"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      enrollments_handler.index(req, auth_ctx)
    }
    ["api", "enrollments", "enroll", course_id] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      enrollments_handler.enroll(req, auth_ctx, course_id)
    }

    ["api", "courses", course_id, "lessons"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      lessons_handler.index(req, auth_ctx, course_id)
    }
    ["api", "courses", course_id, "lessons", lesson_id] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      lessons_handler.show(req, auth_ctx, course_id, lesson_id)
    }
    ["api", "courses", course_id, "lessons", lesson_id, "complete"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      lessons_handler.complete(req, auth_ctx, course_id, lesson_id)
    }

    ["api", "courses", course_id, "quizzes"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      quizzes_handler.index(req, auth_ctx, course_id)
    }
    ["api", "courses", course_id, "quizzes", quiz_id] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      quizzes_handler.show(req, auth_ctx, course_id, quiz_id)
    }
    ["api", "quizzes", quiz_id, "attempts"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      quizzes_handler.attempts(req, auth_ctx, quiz_id)
    }
    ["api", "quizzes", quiz_id, "attempts", "new"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      quizzes_handler.new_attempt(req, auth_ctx, quiz_id)
    }
    ["api", "attempts", attempt_id] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      quizzes_handler.get_attempt(req, auth_ctx, attempt_id)
    }
    ["api", "attempts", attempt_id, "submit"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      quizzes_handler.submit_answer(req, auth_ctx, attempt_id)
    }
    ["api", "attempts", attempt_id, "complete"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      quizzes_handler.complete_attempt(req, auth_ctx, attempt_id)
    }

    // Dashboard
    ["api", "dashboard", "student"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      dashboard_handler.student(req, auth_ctx)
    }
    ["api", "dashboard", "instructor"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      use auth_ctx <- auth_middleware.require_instructor(auth_ctx)
      dashboard_handler.instructor(req, auth_ctx)
    }
    ["api", "dashboard", "admin"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      use auth_ctx <- auth_middleware.require_admin(auth_ctx)
      dashboard_handler.admin(req, auth_ctx)
    }

    // Achievements
    ["api", "achievements"] -> achievements_handler.index(req, ctx)
    ["api", "users", user_id, "achievements"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      achievements_handler.user_achievements(req, auth_ctx, user_id)
    }

    // Instructor routes
    ["api", "instructor", "courses"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      use auth_ctx <- auth_middleware.require_instructor(auth_ctx)
      courses_handler.instructor_courses(req, auth_ctx)
    }
    ["api", "instructor", "courses", id] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      use auth_ctx <- auth_middleware.require_instructor(auth_ctx)
      courses_handler.instructor_course(req, auth_ctx, id)
    }

    // Admin routes
    ["api", "admin", "users"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      use auth_ctx <- auth_middleware.require_admin(auth_ctx)
      dashboard_handler.admin_users(req, auth_ctx)
    }
    ["api", "admin", "courses"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      use auth_ctx <- auth_middleware.require_admin(auth_ctx)
      courses_handler.admin_courses(req, auth_ctx)
    }

    // Training Loop API
    ["api", "training", "skills"] -> training_handler.list_skills(req, ctx)

    ["api", "training", "session", "start"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      training_handler.start_session(req, auth_ctx)
    }
    ["api", "training", "session", session_id] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      training_handler.get_session(req, auth_ctx, session_id)
    }
    ["api", "training", "session", session_id, "next"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      training_handler.next_intervention(req, auth_ctx, session_id)
    }
    ["api", "training", "session", session_id, "end"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      training_handler.end_session(req, auth_ctx, session_id)
    }
    ["api", "training", "intervention", intervention_id, "respond"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      training_handler.respond_to_intervention(req, auth_ctx, intervention_id)
    }
    ["api", "training", "competence"] -> {
      use auth_ctx <- auth_middleware.require_auth(req, ctx)
      training_handler.get_competence(req, auth_ctx)
    }

    // 404 for everything else
    _ -> wisp.not_found()
  }
}

fn health_check() -> Response {
  json.object([
    #("status", json.string("healthy")),
    #("service", json.string("candy-crash")),
  ])
  |> json.to_string_builder
  |> wisp.json_response(200)
}
