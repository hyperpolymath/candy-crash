// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type LessonType {
  Video
  Text
  Quiz
  Interactive
}

pub type Lesson {
  Lesson(
    key: Option(String),
    module_key: String,
    title: String,
    content: Option(String),
    lesson_type: LessonType,
    position: Int,
    duration_minutes: Int,
    published: Bool,
    slug: String,
    video_url: Option(String),
  )
}

pub type LessonProgress {
  LessonProgress(
    key: Option(String),
    user_key: String,
    lesson_key: String,
    completed: Bool,
    completed_at: Option(String),
    time_spent_minutes: Int,
  )
}

pub fn lesson_type_to_string(lt: LessonType) -> String {
  case lt {
    Video -> "video"
    Text -> "text"
    Quiz -> "quiz"
    Interactive -> "interactive"
  }
}

pub fn lesson_type_from_string(s: String) -> LessonType {
  case s {
    "video" -> Video
    "quiz" -> Quiz
    "interactive" -> Interactive
    _ -> Text
  }
}

pub fn decoder(dyn: Dynamic) -> Result(Lesson, List(DecodeError)) {
  dynamic.decode10(
    Lesson,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("module_key", dynamic.string),
    dynamic.field("title", dynamic.string),
    dynamic.optional_field("content", dynamic.string),
    dynamic.field("lesson_type", fn(d) {
      dynamic.string(d)
      |> gleam/result.map(lesson_type_from_string)
    }),
    dynamic.field("position", dynamic.int),
    dynamic.field("duration_minutes", dynamic.int),
    dynamic.field("published", dynamic.bool),
    dynamic.field("slug", dynamic.string),
    dynamic.optional_field("video_url", dynamic.string),
  )(dyn)
}

pub fn progress_decoder(dyn: Dynamic) -> Result(LessonProgress, List(DecodeError)) {
  dynamic.decode6(
    LessonProgress,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("user_key", dynamic.string),
    dynamic.field("lesson_key", dynamic.string),
    dynamic.field("completed", dynamic.bool),
    dynamic.optional_field("completed_at", dynamic.string),
    dynamic.field("time_spent_minutes", dynamic.int),
  )(dyn)
}

pub fn to_json(lesson: Lesson) -> Json {
  json.object([
    #("module_key", json.string(lesson.module_key)),
    #("title", json.string(lesson.title)),
    #("content", case lesson.content {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("lesson_type", json.string(lesson_type_to_string(lesson.lesson_type))),
    #("position", json.int(lesson.position)),
    #("duration_minutes", json.int(lesson.duration_minutes)),
    #("published", json.bool(lesson.published)),
    #("slug", json.string(lesson.slug)),
    #("video_url", case lesson.video_url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

pub fn progress_to_json(progress: LessonProgress) -> Json {
  json.object([
    #("user_key", json.string(progress.user_key)),
    #("lesson_key", json.string(progress.lesson_key)),
    #("completed", json.bool(progress.completed)),
    #("completed_at", case progress.completed_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("time_spent_minutes", json.int(progress.time_spent_minutes)),
  ])
}
