// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import birl
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

import candy_crash/arango/client.{type Connection}
import candy_crash/models/achievement.{type Achievement, type UserAchievement}

/// Check and award achievements for a user
pub fn check_and_award(db: Connection, user_key: String) -> Nil {
  check_first_lesson(db, user_key)
  check_first_quiz(db, user_key)
  check_perfect_score(db, user_key)
  check_lesson_milestones(db, user_key)
  check_quiz_milestones(db, user_key)
  Nil
}

/// Award "First Steps" achievement for completing first lesson
fn check_first_lesson(db: Connection, user_key: String) -> Nil {
  let query = "
    LET completed = LENGTH(
      FOR p IN lesson_progress
      FILTER p.user_key == @user_key AND p.completed == true
      RETURN p
    )
    LET has_achievement = LENGTH(
      FOR ua IN user_achievements
      FILTER ua.user_key == @user_key
      LET a = DOCUMENT('achievements', ua.achievement_key)
      FILTER a.title == 'First Steps'
      RETURN ua
    ) > 0
    FILTER completed >= 1 AND !has_achievement
    LET achievement = FIRST(
      FOR a IN achievements
      FILTER a.title == 'First Steps'
      RETURN a
    )
    FILTER achievement != null
    INSERT {
      user_key: @user_key,
      achievement_key: achievement._key,
      earned_at: @now
    } INTO user_achievements
    RETURN NEW
  "

  let now = birl.now() |> birl.to_iso8601
  let _ = client.query(db, query, [
    #("user_key", json.string(user_key)),
    #("now", json.string(now)),
  ], dynamic.dynamic)

  Nil
}

/// Award "Quiz Master" achievement for first quiz completion
fn check_first_quiz(db: Connection, user_key: String) -> Nil {
  let query = "
    LET completed = LENGTH(
      FOR a IN quiz_attempts
      FILTER a.user_key == @user_key AND a.completed_at != null AND a.passed == true
      RETURN a
    )
    LET has_achievement = LENGTH(
      FOR ua IN user_achievements
      FILTER ua.user_key == @user_key
      LET a = DOCUMENT('achievements', ua.achievement_key)
      FILTER a.title == 'Quiz Master'
      RETURN ua
    ) > 0
    FILTER completed >= 1 AND !has_achievement
    LET achievement = FIRST(
      FOR a IN achievements
      FILTER a.title == 'Quiz Master'
      RETURN a
    )
    FILTER achievement != null
    INSERT {
      user_key: @user_key,
      achievement_key: achievement._key,
      earned_at: @now
    } INTO user_achievements
    RETURN NEW
  "

  let now = birl.now() |> birl.to_iso8601
  let _ = client.query(db, query, [
    #("user_key", json.string(user_key)),
    #("now", json.string(now)),
  ], dynamic.dynamic)

  Nil
}

/// Award "Perfect Score" achievement for 100% on a quiz
fn check_perfect_score(db: Connection, user_key: String) -> Nil {
  let query = "
    LET has_perfect = LENGTH(
      FOR a IN quiz_attempts
      FILTER a.user_key == @user_key AND a.score == 100
      RETURN a
    ) > 0
    LET has_achievement = LENGTH(
      FOR ua IN user_achievements
      FILTER ua.user_key == @user_key
      LET a = DOCUMENT('achievements', ua.achievement_key)
      FILTER a.title == 'Perfect Score'
      RETURN ua
    ) > 0
    FILTER has_perfect AND !has_achievement
    LET achievement = FIRST(
      FOR a IN achievements
      FILTER a.title == 'Perfect Score'
      RETURN a
    )
    FILTER achievement != null
    INSERT {
      user_key: @user_key,
      achievement_key: achievement._key,
      earned_at: @now
    } INTO user_achievements
    RETURN NEW
  "

  let now = birl.now() |> birl.to_iso8601
  let _ = client.query(db, query, [
    #("user_key", json.string(user_key)),
    #("now", json.string(now)),
  ], dynamic.dynamic)

  Nil
}

/// Award lesson milestone achievements (10, 25, 50 lessons)
fn check_lesson_milestones(db: Connection, user_key: String) -> Nil {
  let milestones = [
    #(10, "Lesson Champion", "bronze"),
    #(25, "Learning Machine", "silver"),
    #(50, "Knowledge Seeker", "gold"),
  ]

  list.each(milestones, fn(milestone) {
    let #(count, title, badge_type) = milestone
    check_lesson_milestone(db, user_key, count, title)
  })
}

fn check_lesson_milestone(db: Connection, user_key: String, count: Int, title: String) -> Nil {
  let query = "
    LET completed = LENGTH(
      FOR p IN lesson_progress
      FILTER p.user_key == @user_key AND p.completed == true
      RETURN p
    )
    LET has_achievement = LENGTH(
      FOR ua IN user_achievements
      FILTER ua.user_key == @user_key
      LET a = DOCUMENT('achievements', ua.achievement_key)
      FILTER a.title == @title
      RETURN ua
    ) > 0
    FILTER completed >= @count AND !has_achievement
    LET achievement = FIRST(
      FOR a IN achievements
      FILTER a.title == @title
      RETURN a
    )
    FILTER achievement != null
    INSERT {
      user_key: @user_key,
      achievement_key: achievement._key,
      earned_at: @now
    } INTO user_achievements
    RETURN NEW
  "

  let now = birl.now() |> birl.to_iso8601
  let _ = client.query(db, query, [
    #("user_key", json.string(user_key)),
    #("count", json.int(count)),
    #("title", json.string(title)),
    #("now", json.string(now)),
  ], dynamic.dynamic)

  Nil
}

/// Award quiz milestone achievements (5, 10, 25 quizzes passed)
fn check_quiz_milestones(db: Connection, user_key: String) -> Nil {
  let milestones = [
    #(5, "Quiz Enthusiast", "bronze"),
    #(10, "Quiz Expert", "silver"),
    #(25, "Quiz Legend", "platinum"),
  ]

  list.each(milestones, fn(milestone) {
    let #(count, title, badge_type) = milestone
    check_quiz_milestone(db, user_key, count, title)
  })
}

fn check_quiz_milestone(db: Connection, user_key: String, count: Int, title: String) -> Nil {
  let query = "
    LET passed = LENGTH(
      FOR a IN quiz_attempts
      FILTER a.user_key == @user_key AND a.passed == true
      RETURN a
    )
    LET has_achievement = LENGTH(
      FOR ua IN user_achievements
      FILTER ua.user_key == @user_key
      LET a = DOCUMENT('achievements', ua.achievement_key)
      FILTER a.title == @title
      RETURN ua
    ) > 0
    FILTER passed >= @count AND !has_achievement
    LET achievement = FIRST(
      FOR a IN achievements
      FILTER a.title == @title
      RETURN a
    )
    FILTER achievement != null
    INSERT {
      user_key: @user_key,
      achievement_key: achievement._key,
      earned_at: @now
    } INTO user_achievements
    RETURN NEW
  "

  let now = birl.now() |> birl.to_iso8601
  let _ = client.query(db, query, [
    #("user_key", json.string(user_key)),
    #("count", json.int(count)),
    #("title", json.string(title)),
    #("now", json.string(now)),
  ], dynamic.dynamic)

  Nil
}

/// Seed default achievements
pub fn seed_achievements(db: Connection) -> Nil {
  let achievements = [
    #("First Steps", "Complete your first lesson", "bronze", 10),
    #("Quiz Master", "Pass your first quiz", "bronze", 15),
    #("Perfect Score", "Get 100% on a quiz", "gold", 50),
    #("Lesson Champion", "Complete 10 lessons", "bronze", 25),
    #("Learning Machine", "Complete 25 lessons", "silver", 50),
    #("Knowledge Seeker", "Complete 50 lessons", "gold", 100),
    #("Quiz Enthusiast", "Pass 5 quizzes", "bronze", 25),
    #("Quiz Expert", "Pass 10 quizzes", "silver", 50),
    #("Quiz Legend", "Pass 25 quizzes", "platinum", 150),
  ]

  list.each(achievements, fn(a) {
    let #(title, description, badge_type, points) = a
    let doc = json.object([
      #("title", json.string(title)),
      #("description", json.string(description)),
      #("badge_type", json.string(badge_type)),
      #("criteria", json.string(description)),
      #("points", json.int(points)),
    ])
    let _ = client.insert_document(db, "achievements", doc, achievement.decoder)
    Nil
  })
}
