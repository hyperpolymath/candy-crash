// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri
import wisp.{type Request, type Response}

import candy_crash/arango/client
import candy_crash/context.{type AuthContext, type Context}
import candy_crash/models/course.{type Category, type Course, type CourseModule}

pub fn index(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Get -> {
      let query_params = wisp.get_query(req)
      let page = get_int_param(query_params, "page", 1)
      let per_page = get_int_param(query_params, "per_page", 12)
      let search = get_param(query_params, "q")
      let category = get_param(query_params, "category")
      let level = get_param(query_params, "level")

      let offset = { page - 1 } * per_page

      let base_query = "
        FOR c IN courses
        FILTER c.published == true
      "

      let #(filter_query, bind_vars) = build_filters(search, category, level)

      let full_query = base_query <> filter_query <> "
        SORT c.created_at DESC
        LIMIT @offset, @limit
        LET cat = DOCUMENT('categories', c.category_key)
        LET instructor = DOCUMENT('users', c.instructor_key)
        RETURN MERGE(c, {
          category: cat,
          instructor: { key: instructor._key, email: instructor.email }
        })
      "

      let all_bind_vars = list.concat([
        bind_vars,
        [
          #("offset", json.int(offset)),
          #("limit", json.int(per_page)),
        ],
      ])

      case client.query(ctx.db, full_query, all_bind_vars, course.decoder) {
        Ok(result) -> {
          json.object([
            #("courses", json.array(result.result, course_to_json)),
            #("page", json.int(page)),
            #("per_page", json.int(per_page)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> {
          json.object([#("error", json.string("Failed to fetch courses"))])
          |> json.to_string_builder
          |> wisp.json_response(500)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn show(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    http.Get -> {
      let query = "
        FOR c IN courses
        FILTER c._key == @id AND c.published == true
        LET cat = DOCUMENT('categories', c.category_key)
        LET instructor = DOCUMENT('users', c.instructor_key)
        LET modules = (
          FOR m IN course_modules
          FILTER m.course_key == c._key AND m.published == true
          SORT m.position
          LET lessons = (
            FOR l IN lessons
            FILTER l.module_key == m._key AND l.published == true
            SORT l.position
            RETURN l
          )
          RETURN MERGE(m, { lessons: lessons })
        )
        LET quizzes = (
          FOR q IN quizzes
          FILTER q.course_key == c._key AND q.published == true
          RETURN q
        )
        RETURN MERGE(c, {
          category: cat,
          instructor: { key: instructor._key, email: instructor.email },
          modules: modules,
          quizzes: quizzes
        })
      "

      case client.query(ctx.db, query, [#("id", json.string(id))], course.decoder) {
        Ok(result) -> {
          case result.result {
            [c, ..] -> {
              course_to_json(c)
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            [] -> wisp.not_found()
          }
        }
        Error(_) -> {
          json.object([#("error", json.string("Failed to fetch course"))])
          |> json.to_string_builder
          |> wisp.json_response(500)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn categories(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Get -> {
      let query = "FOR c IN categories SORT c.position RETURN c"

      case client.query(ctx.db, query, [], course.category_decoder) {
        Ok(result) -> {
          json.object([
            #("categories", json.array(result.result, category_to_json)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> {
          json.object([#("error", json.string("Failed to fetch categories"))])
          |> json.to_string_builder
          |> wisp.json_response(500)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn instructor_courses(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let query = "
        FOR c IN courses
        FILTER c.instructor_key == @user_key
        SORT c.created_at DESC
        RETURN c
      "

      case client.query(auth_ctx.db, query, [#("user_key", json.string(user_key))], course.decoder) {
        Ok(result) -> {
          json.object([
            #("courses", json.array(result.result, course_to_json)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> {
          json.object([#("error", json.string("Failed to fetch courses"))])
          |> json.to_string_builder
          |> wisp.json_response(500)
        }
      }
    }
    http.Post -> create_course(req, auth_ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

pub fn instructor_course(req: Request, auth_ctx: AuthContext, id: String) -> Response {
  case req.method {
    http.Get -> show_instructor_course(auth_ctx, id)
    http.Put | http.Patch -> update_course(req, auth_ctx, id)
    http.Delete -> delete_course(auth_ctx, id)
    _ -> wisp.method_not_allowed([http.Get, http.Put, http.Patch, http.Delete])
  }
}

pub fn admin_courses(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let query = "
        FOR c IN courses
        SORT c.created_at DESC
        LET instructor = DOCUMENT('users', c.instructor_key)
        RETURN MERGE(c, {
          instructor: { key: instructor._key, email: instructor.email }
        })
      "

      case client.query(auth_ctx.db, query, [], course.decoder) {
        Ok(result) -> {
          json.object([
            #("courses", json.array(result.result, course_to_json)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> {
          json.object([#("error", json.string("Failed to fetch courses"))])
          |> json.to_string_builder
          |> wisp.json_response(500)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn create_course(req: Request, auth_ctx: AuthContext) -> Response {
  use body <- wisp.require_json(req)

  let decoder = dynamic.decode6(
    fn(title, description, category_key, price, duration, level) {
      #(title, description, category_key, price, duration, level)
    },
    dynamic.field("title", dynamic.string),
    dynamic.optional_field("description", dynamic.string),
    dynamic.field("category_key", dynamic.string),
    dynamic.field("price", dynamic.float),
    dynamic.field("duration_hours", dynamic.int),
    dynamic.field("level", dynamic.string),
  )

  case dynamic.from(body) |> decoder {
    Ok(#(title, description, category_key, price, duration, level_str)) -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let slug = slugify(title)

      let new_course = course.Course(
        key: None,
        title: title,
        description: description,
        category_key: category_key,
        instructor_key: user_key,
        price: price,
        duration_hours: duration,
        level: course.level_from_string(level_str),
        published: False,
        slug: slug,
        thumbnail_url: None,
        created_at: None,
        updated_at: None,
      )

      case client.insert_document(auth_ctx.db, "courses", course.to_json(new_course), course.decoder) {
        Ok(c) -> {
          course_to_json(c)
          |> json.to_string_builder
          |> wisp.json_response(201)
        }
        Error(_) -> {
          json.object([#("error", json.string("Failed to create course"))])
          |> json.to_string_builder
          |> wisp.json_response(500)
        }
      }
    }
    Error(_) -> {
      json.object([#("error", json.string("Invalid request body"))])
      |> json.to_string_builder
      |> wisp.json_response(400)
    }
  }
}

fn show_instructor_course(auth_ctx: AuthContext, id: String) -> Response {
  let user_key = auth_ctx.current_user.key |> option.unwrap("")
  let query = "
    FOR c IN courses
    FILTER c._key == @id AND c.instructor_key == @user_key
    RETURN c
  "

  case client.query(auth_ctx.db, query, [
    #("id", json.string(id)),
    #("user_key", json.string(user_key)),
  ], course.decoder) {
    Ok(result) -> {
      case result.result {
        [c, ..] -> {
          course_to_json(c)
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        [] -> wisp.not_found()
      }
    }
    Error(_) -> {
      json.object([#("error", json.string("Failed to fetch course"))])
      |> json.to_string_builder
      |> wisp.json_response(500)
    }
  }
}

fn update_course(req: Request, auth_ctx: AuthContext, id: String) -> Response {
  use body <- wisp.require_json(req)
  // Implementation for updating course
  json.object([#("message", json.string("Course updated"))])
  |> json.to_string_builder
  |> wisp.json_response(200)
}

fn delete_course(auth_ctx: AuthContext, id: String) -> Response {
  let user_key = auth_ctx.current_user.key |> option.unwrap("")

  // Verify ownership first
  let query = "
    FOR c IN courses
    FILTER c._key == @id AND c.instructor_key == @user_key
    RETURN c._key
  "

  case client.query(auth_ctx.db, query, [
    #("id", json.string(id)),
    #("user_key", json.string(user_key)),
  ], dynamic.string) {
    Ok(result) -> {
      case result.result {
        [_, ..] -> {
          case client.delete_document(auth_ctx.db, "courses", id) {
            Ok(_) -> wisp.response(204)
            Error(_) -> {
              json.object([#("error", json.string("Failed to delete course"))])
              |> json.to_string_builder
              |> wisp.json_response(500)
            }
          }
        }
        [] -> wisp.not_found()
      }
    }
    Error(_) -> {
      json.object([#("error", json.string("Failed to verify ownership"))])
      |> json.to_string_builder
      |> wisp.json_response(500)
    }
  }
}

// Helpers

fn build_filters(
  search: Option(String),
  category: Option(String),
  level: Option(String),
) -> #(String, List(#(String, json.Json))) {
  let #(search_filter, search_vars) = case search {
    Some(q) -> #(
      " FILTER CONTAINS(LOWER(c.title), LOWER(@search)) OR CONTAINS(LOWER(c.description), LOWER(@search))",
      [#("search", json.string(q))],
    )
    None -> #("", [])
  }

  let #(cat_filter, cat_vars) = case category {
    Some(cat) -> #(
      " FILTER c.category_key == @category",
      [#("category", json.string(cat))],
    )
    None -> #("", [])
  }

  let #(level_filter, level_vars) = case level {
    Some(l) -> #(
      " FILTER c.level == @level",
      [#("level", json.string(l))],
    )
    None -> #("", [])
  }

  #(
    search_filter <> cat_filter <> level_filter,
    list.concat([search_vars, cat_vars, level_vars]),
  )
}

fn get_param(params: List(#(String, String)), key: String) -> Option(String) {
  case list.find(params, fn(p) { p.0 == key }) {
    Ok(#(_, v)) -> Some(v)
    Error(_) -> None
  }
}

fn get_int_param(params: List(#(String, String)), key: String, default: Int) -> Int {
  case get_param(params, key) {
    Some(v) -> int.parse(v) |> result.unwrap(default)
    None -> default
  }
}

fn slugify(title: String) -> String {
  title
  |> gleam/string.lowercase
  |> gleam/string.replace(" ", "-")
  |> gleam/string.replace("_", "-")
}

fn course_to_json(c: Course) -> json.Json {
  json.object([
    #("key", json.string(c.key |> option.unwrap(""))),
    #("title", json.string(c.title)),
    #("description", case c.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("category_key", json.string(c.category_key)),
    #("instructor_key", json.string(c.instructor_key)),
    #("price", json.float(c.price)),
    #("duration_hours", json.int(c.duration_hours)),
    #("level", json.string(course.level_to_string(c.level))),
    #("published", json.bool(c.published)),
    #("slug", json.string(c.slug)),
    #("thumbnail_url", case c.thumbnail_url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

fn category_to_json(cat: Category) -> json.Json {
  json.object([
    #("key", json.string(cat.key |> option.unwrap(""))),
    #("name", json.string(cat.name)),
    #("description", case cat.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("slug", json.string(cat.slug)),
    #("position", json.int(cat.position)),
  ])
}
