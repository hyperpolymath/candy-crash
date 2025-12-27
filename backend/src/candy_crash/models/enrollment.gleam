// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type EnrollmentStatus {
  Active
  Completed
  Dropped
}

pub type Enrollment {
  Enrollment(
    key: Option(String),
    user_key: String,
    course_key: String,
    enrolled_at: String,
    completed_at: Option(String),
    progress: Int,
    status: EnrollmentStatus,
  )
}

pub fn status_to_string(status: EnrollmentStatus) -> String {
  case status {
    Active -> "active"
    Completed -> "completed"
    Dropped -> "dropped"
  }
}

pub fn status_from_string(s: String) -> EnrollmentStatus {
  case s {
    "completed" -> Completed
    "dropped" -> Dropped
    _ -> Active
  }
}

pub fn decoder(dyn: Dynamic) -> Result(Enrollment, List(DecodeError)) {
  dynamic.decode7(
    Enrollment,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("user_key", dynamic.string),
    dynamic.field("course_key", dynamic.string),
    dynamic.field("enrolled_at", dynamic.string),
    dynamic.optional_field("completed_at", dynamic.string),
    dynamic.field("progress", dynamic.int),
    dynamic.field("status", fn(d) {
      dynamic.string(d)
      |> gleam/result.map(status_from_string)
    }),
  )(dyn)
}

pub fn to_json(enrollment: Enrollment) -> Json {
  json.object([
    #("user_key", json.string(enrollment.user_key)),
    #("course_key", json.string(enrollment.course_key)),
    #("enrolled_at", json.string(enrollment.enrolled_at)),
    #("completed_at", case enrollment.completed_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("progress", json.int(enrollment.progress)),
    #("status", json.string(status_to_string(enrollment.status))),
  ])
}

pub fn new_enrollment(user_key: String, course_key: String, enrolled_at: String) -> Enrollment {
  Enrollment(
    key: None,
    user_key: user_key,
    course_key: course_key,
    enrolled_at: enrolled_at,
    completed_at: None,
    progress: 0,
    status: Active,
  )
}

pub fn is_active(enrollment: Enrollment) -> Bool {
  enrollment.status == Active
}

pub fn is_completed(enrollment: Enrollment) -> Bool {
  enrollment.status == Completed
}
