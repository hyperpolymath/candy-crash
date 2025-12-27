// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic
import gleam/http
import gleam/json
import gleam/option.{type Option, None, Some}
import wisp.{type Request, type Response}

import candy_crash/arango/client
import candy_crash/context.{type AuthContext, type Context}
import candy_crash/models/achievement.{type Achievement, type UserAchievement}

pub fn index(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Get -> {
      let query = "
        FOR a IN achievements
        SORT a.points DESC
        RETURN a
      "

      case client.query(ctx.db, query, [], achievement.decoder) {
        Ok(result) -> {
          json.object([
            #("achievements", json.array(result.result, achievement_to_json)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to fetch achievements", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

pub fn user_achievements(req: Request, auth_ctx: AuthContext, user_id: String) -> Response {
  case req.method {
    http.Get -> {
      // Users can only view their own achievements unless admin
      let current_user_key = auth_ctx.current_user.key |> option.unwrap("")
      let can_view = current_user_key == user_id ||
        auth_ctx.current_user.role == achievement.Admin

      case can_view {
        True -> {
          let query = "
            FOR ua IN user_achievements
            FILTER ua.user_key == @user_id
            SORT ua.earned_at DESC
            LET achievement = DOCUMENT('achievements', ua.achievement_key)
            RETURN MERGE(ua, { achievement: achievement })
          "

          case client.query(auth_ctx.db, query, [
            #("user_id", json.string(user_id)),
          ], achievement.user_achievement_decoder) {
            Ok(result) -> {
              json.object([
                #("user_achievements", json.array(result.result, user_achievement_to_json)),
              ])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            Error(_) -> error_response("Failed to fetch achievements", 500)
          }
        }
        False -> error_response("Access denied", 403)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn achievement_to_json(a: Achievement) -> json.Json {
  json.object([
    #("key", json.string(a.key |> option.unwrap(""))),
    #("title", json.string(a.title)),
    #("description", case a.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("badge_type", json.string(achievement.badge_type_to_string(a.badge_type))),
    #("criteria", case a.criteria {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("points", json.int(a.points)),
    #("badge_image_url", case a.badge_image_url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

fn user_achievement_to_json(ua: UserAchievement) -> json.Json {
  json.object([
    #("key", json.string(ua.key |> option.unwrap(""))),
    #("user_key", json.string(ua.user_key)),
    #("achievement_key", json.string(ua.achievement_key)),
    #("earned_at", json.string(ua.earned_at)),
  ])
}

fn error_response(message: String, status: Int) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(status)
}
