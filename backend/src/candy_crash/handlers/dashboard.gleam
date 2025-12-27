// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic
import gleam/http
import gleam/json
import gleam/option.{type Option, None, Some}
import wisp.{type Request, type Response}

import candy_crash/arango/client
import candy_crash/context.{type AuthContext}

pub fn student(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      let query = "
        LET enrollments = (
          FOR e IN enrollments
          FILTER e.user_key == @user_key
          SORT e.enrolled_at DESC
          LIMIT 5
          LET course = DOCUMENT('courses', e.course_key)
          RETURN MERGE(e, { course: course })
        )
        LET completed_lessons = LENGTH(
          FOR p IN lesson_progress
          FILTER p.user_key == @user_key AND p.completed == true
          RETURN p
        )
        LET quiz_attempts = (
          FOR a IN quiz_attempts
          FILTER a.user_key == @user_key AND a.completed_at != null
          SORT a.completed_at DESC
          LIMIT 5
          LET quiz = DOCUMENT('quizzes', a.quiz_key)
          RETURN MERGE(a, { quiz: quiz })
        )
        LET achievements = (
          FOR ua IN user_achievements
          FILTER ua.user_key == @user_key
          SORT ua.earned_at DESC
          LIMIT 5
          LET achievement = DOCUMENT('achievements', ua.achievement_key)
          RETURN MERGE(ua, { achievement: achievement })
        )
        LET total_points = SUM(
          FOR ua IN user_achievements
          FILTER ua.user_key == @user_key
          LET achievement = DOCUMENT('achievements', ua.achievement_key)
          RETURN achievement.points
        )
        RETURN {
          enrollments: enrollments,
          completed_lessons: completed_lessons,
          quiz_attempts: quiz_attempts,
          achievements: achievements,
          total_points: total_points,
          enrollments_count: LENGTH(FOR e IN enrollments FILTER e.user_key == @user_key RETURN e),
          achievements_count: LENGTH(FOR ua IN user_achievements FILTER ua.user_key == @user_key RETURN ua)
        }
      "

      case client.query(auth_ctx.db, query, [
        #("user_key", json.string(user_key)),
      ], dynamic.dynamic) {
        Ok(result) -> {
          json.object([
            #("dashboard", json.string("student")),
            #("data", json.array(result.result, fn(d) { json.null() })),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch dashboard", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn instructor(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      let query = "
        LET courses = (
          FOR c IN courses
          FILTER c.instructor_key == @user_key
          LET enrollments_count = LENGTH(
            FOR e IN enrollments
            FILTER e.course_key == c._key
            RETURN e
          )
          RETURN MERGE(c, { enrollments_count: enrollments_count })
        )
        LET total_students = LENGTH(
          FOR c IN courses
          FILTER c.instructor_key == @user_key
          FOR e IN enrollments
          FILTER e.course_key == c._key
          COLLECT AGGREGATE student = UNIQUE(e.user_key)
          RETURN student
        )
        LET recent_enrollments = (
          FOR c IN courses
          FILTER c.instructor_key == @user_key
          FOR e IN enrollments
          FILTER e.course_key == c._key
          SORT e.enrolled_at DESC
          LIMIT 10
          LET student = DOCUMENT('users', e.user_key)
          LET course = DOCUMENT('courses', e.course_key)
          RETURN {
            enrollment: e,
            student: { key: student._key, email: student.email },
            course: { key: course._key, title: course.title }
          }
        )
        RETURN {
          courses: courses,
          total_students: total_students,
          recent_enrollments: recent_enrollments,
          courses_count: LENGTH(courses)
        }
      "

      case client.query(auth_ctx.db, query, [
        #("user_key", json.string(user_key)),
      ], dynamic.dynamic) {
        Ok(result) -> {
          json.object([
            #("dashboard", json.string("instructor")),
            #("data", json.array(result.result, fn(d) { json.null() })),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch dashboard", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn admin(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let query = "
        LET users_count = LENGTH(FOR u IN users RETURN u)
        LET courses_count = LENGTH(FOR c IN courses RETURN c)
        LET enrollments_count = LENGTH(FOR e IN enrollments RETURN e)
        LET quiz_attempts_count = LENGTH(FOR a IN quiz_attempts RETURN a)
        LET popular_courses = (
          FOR c IN courses
          LET enrollment_count = LENGTH(
            FOR e IN enrollments
            FILTER e.course_key == c._key
            RETURN e
          )
          SORT enrollment_count DESC
          LIMIT 5
          RETURN MERGE(c, { enrollment_count: enrollment_count })
        )
        LET recent_users = (
          FOR u IN users
          SORT u.created_at DESC
          LIMIT 10
          RETURN { key: u._key, email: u.email, role: u.role, created_at: u.created_at }
        )
        RETURN {
          users_count: users_count,
          courses_count: courses_count,
          enrollments_count: enrollments_count,
          quiz_attempts_count: quiz_attempts_count,
          popular_courses: popular_courses,
          recent_users: recent_users
        }
      "

      case client.query(auth_ctx.db, query, [], dynamic.dynamic) {
        Ok(result) -> {
          json.object([
            #("dashboard", json.string("admin")),
            #("data", json.array(result.result, fn(d) { json.null() })),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch dashboard", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn admin_users(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let query = "
        FOR u IN users
        SORT u.created_at DESC
        RETURN { key: u._key, email: u.email, role: u.role, created_at: u.created_at }
      "

      case client.query(auth_ctx.db, query, [], dynamic.dynamic) {
        Ok(result) -> {
          json.object([
            #("users", json.array(result.result, fn(d) { json.null() })),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch users", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn error_response(message: String, status: Int) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(status)
}
