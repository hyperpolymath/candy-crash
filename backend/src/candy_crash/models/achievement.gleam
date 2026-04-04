// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type BadgeType {
  Bronze
  Silver
  Gold
  Platinum
}

pub type Achievement {
  Achievement(
    key: Option(String),
    title: String,
    description: Option(String),
    badge_type: BadgeType,
    criteria: Option(String),
    points: Int,
    badge_image_url: Option(String),
  )
}

pub type UserAchievement {
  UserAchievement(
    key: Option(String),
    user_key: String,
    achievement_key: String,
    earned_at: String,
  )
}

pub fn badge_type_to_string(bt: BadgeType) -> String {
  case bt {
    Bronze -> "bronze"
    Silver -> "silver"
    Gold -> "gold"
    Platinum -> "platinum"
  }
}

pub fn badge_type_from_string(s: String) -> BadgeType {
  case s {
    "silver" -> Silver
    "gold" -> Gold
    "platinum" -> Platinum
    _ -> Bronze
  }
}

pub fn decoder(dyn: Dynamic) -> Result(Achievement, List(DecodeError)) {
  dynamic.decode7(
    Achievement,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("title", dynamic.string),
    dynamic.optional_field("description", dynamic.string),
    dynamic.field("badge_type", fn(d) {
      dynamic.string(d)
      |> gleam/result.map(badge_type_from_string)
    }),
    dynamic.optional_field("criteria", dynamic.string),
    dynamic.field("points", dynamic.int),
    dynamic.optional_field("badge_image_url", dynamic.string),
  )(dyn)
}

pub fn user_achievement_decoder(dyn: Dynamic) -> Result(UserAchievement, List(DecodeError)) {
  dynamic.decode4(
    UserAchievement,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("user_key", dynamic.string),
    dynamic.field("achievement_key", dynamic.string),
    dynamic.field("earned_at", dynamic.string),
  )(dyn)
}

pub fn to_json(achievement: Achievement) -> Json {
  json.object([
    #("title", json.string(achievement.title)),
    #("description", case achievement.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("badge_type", json.string(badge_type_to_string(achievement.badge_type))),
    #("criteria", case achievement.criteria {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("points", json.int(achievement.points)),
    #("badge_image_url", case achievement.badge_image_url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

pub fn user_achievement_to_json(ua: UserAchievement) -> Json {
  json.object([
    #("user_key", json.string(ua.user_key)),
    #("achievement_key", json.string(ua.achievement_key)),
    #("earned_at", json.string(ua.earned_at)),
  ])
}
