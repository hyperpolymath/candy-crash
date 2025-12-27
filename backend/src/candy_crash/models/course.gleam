// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type Level {
  Beginner
  Intermediate
  Advanced
}

pub type Course {
  Course(
    key: Option(String),
    title: String,
    description: Option(String),
    category_key: String,
    instructor_key: String,
    price: Float,
    duration_hours: Int,
    level: Level,
    published: Bool,
    slug: String,
    thumbnail_url: Option(String),
    created_at: Option(String),
    updated_at: Option(String),
  )
}

pub type Category {
  Category(
    key: Option(String),
    name: String,
    description: Option(String),
    slug: String,
    position: Int,
  )
}

pub type CourseModule {
  CourseModule(
    key: Option(String),
    course_key: String,
    title: String,
    description: Option(String),
    position: Int,
    published: Bool,
  )
}

pub fn level_to_string(level: Level) -> String {
  case level {
    Beginner -> "beginner"
    Intermediate -> "intermediate"
    Advanced -> "advanced"
  }
}

pub fn level_from_string(s: String) -> Level {
  case s {
    "intermediate" -> Intermediate
    "advanced" -> Advanced
    _ -> Beginner
  }
}

pub fn decoder(dyn: Dynamic) -> Result(Course, List(DecodeError)) {
  dynamic.decode13(
    Course,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("title", dynamic.string),
    dynamic.optional_field("description", dynamic.string),
    dynamic.field("category_key", dynamic.string),
    dynamic.field("instructor_key", dynamic.string),
    dynamic.field("price", dynamic.float),
    dynamic.field("duration_hours", dynamic.int),
    dynamic.field("level", fn(d) {
      dynamic.string(d)
      |> gleam/result.map(level_from_string)
    }),
    dynamic.field("published", dynamic.bool),
    dynamic.field("slug", dynamic.string),
    dynamic.optional_field("thumbnail_url", dynamic.string),
    dynamic.optional_field("created_at", dynamic.string),
    dynamic.optional_field("updated_at", dynamic.string),
  )(dyn)
}

pub fn category_decoder(dyn: Dynamic) -> Result(Category, List(DecodeError)) {
  dynamic.decode5(
    Category,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.optional_field("description", dynamic.string),
    dynamic.field("slug", dynamic.string),
    dynamic.field("position", dynamic.int),
  )(dyn)
}

pub fn module_decoder(dyn: Dynamic) -> Result(CourseModule, List(DecodeError)) {
  dynamic.decode6(
    CourseModule,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("course_key", dynamic.string),
    dynamic.field("title", dynamic.string),
    dynamic.optional_field("description", dynamic.string),
    dynamic.field("position", dynamic.int),
    dynamic.field("published", dynamic.bool),
  )(dyn)
}

pub fn to_json(course: Course) -> Json {
  json.object([
    #("title", json.string(course.title)),
    #("description", case course.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("category_key", json.string(course.category_key)),
    #("instructor_key", json.string(course.instructor_key)),
    #("price", json.float(course.price)),
    #("duration_hours", json.int(course.duration_hours)),
    #("level", json.string(level_to_string(course.level))),
    #("published", json.bool(course.published)),
    #("slug", json.string(course.slug)),
    #("thumbnail_url", case course.thumbnail_url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

pub fn category_to_json(cat: Category) -> Json {
  json.object([
    #("name", json.string(cat.name)),
    #("description", case cat.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("slug", json.string(cat.slug)),
    #("position", json.int(cat.position)),
  ])
}

pub fn module_to_json(mod: CourseModule) -> Json {
  json.object([
    #("course_key", json.string(mod.course_key)),
    #("title", json.string(mod.title)),
    #("description", case mod.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("position", json.int(mod.position)),
    #("published", json.bool(mod.published)),
  ])
}
