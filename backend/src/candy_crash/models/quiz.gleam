// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type QuizType {
  Practice
  Exam
  ModuleTest
  FinalExam
}

pub type QuestionType {
  MultipleChoice
  TrueFalse
  TextAnswer
}

pub type Quiz {
  Quiz(
    key: Option(String),
    course_key: String,
    title: String,
    description: Option(String),
    passing_score: Int,
    time_limit_minutes: Option(Int),
    quiz_type: QuizType,
    published: Bool,
    max_attempts: Option(Int),
  )
}

pub type Question {
  Question(
    key: Option(String),
    content: String,
    explanation: Option(String),
    difficulty: Int,
    category_key: String,
    question_type: QuestionType,
    points: Int,
    image_url: Option(String),
  )
}

pub type QuestionOption {
  QuestionOption(
    key: Option(String),
    question_key: String,
    content: String,
    is_correct: Bool,
    position: Int,
  )
}

pub type QuizQuestion {
  QuizQuestion(
    key: Option(String),
    quiz_key: String,
    question_key: String,
    position: Int,
  )
}

pub type QuizAttempt {
  QuizAttempt(
    key: Option(String),
    user_key: String,
    quiz_key: String,
    score: Option(Float),
    started_at: String,
    completed_at: Option(String),
    passed: Option(Bool),
  )
}

pub type QuizAnswer {
  QuizAnswer(
    key: Option(String),
    attempt_key: String,
    question_key: String,
    option_key: Option(String),
    answer_text: Option(String),
    is_correct: Option(Bool),
    points_earned: Int,
  )
}

pub fn quiz_type_to_string(qt: QuizType) -> String {
  case qt {
    Practice -> "practice"
    Exam -> "exam"
    ModuleTest -> "module_test"
    FinalExam -> "final_exam"
  }
}

pub fn quiz_type_from_string(s: String) -> QuizType {
  case s {
    "exam" -> Exam
    "module_test" -> ModuleTest
    "final_exam" -> FinalExam
    _ -> Practice
  }
}

pub fn question_type_to_string(qt: QuestionType) -> String {
  case qt {
    MultipleChoice -> "multiple_choice"
    TrueFalse -> "true_false"
    TextAnswer -> "text"
  }
}

pub fn question_type_from_string(s: String) -> QuestionType {
  case s {
    "true_false" -> TrueFalse
    "text" -> TextAnswer
    _ -> MultipleChoice
  }
}

pub fn quiz_decoder(dyn: Dynamic) -> Result(Quiz, List(DecodeError)) {
  dynamic.decode9(
    Quiz,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("course_key", dynamic.string),
    dynamic.field("title", dynamic.string),
    dynamic.optional_field("description", dynamic.string),
    dynamic.field("passing_score", dynamic.int),
    dynamic.optional_field("time_limit_minutes", dynamic.int),
    dynamic.field("quiz_type", fn(d) {
      dynamic.string(d)
      |> gleam/result.map(quiz_type_from_string)
    }),
    dynamic.field("published", dynamic.bool),
    dynamic.optional_field("max_attempts", dynamic.int),
  )(dyn)
}

pub fn question_decoder(dyn: Dynamic) -> Result(Question, List(DecodeError)) {
  dynamic.decode8(
    Question,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("content", dynamic.string),
    dynamic.optional_field("explanation", dynamic.string),
    dynamic.field("difficulty", dynamic.int),
    dynamic.field("category_key", dynamic.string),
    dynamic.field("question_type", fn(d) {
      dynamic.string(d)
      |> gleam/result.map(question_type_from_string)
    }),
    dynamic.field("points", dynamic.int),
    dynamic.optional_field("image_url", dynamic.string),
  )(dyn)
}

pub fn option_decoder(dyn: Dynamic) -> Result(QuestionOption, List(DecodeError)) {
  dynamic.decode5(
    QuestionOption,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("question_key", dynamic.string),
    dynamic.field("content", dynamic.string),
    dynamic.field("is_correct", dynamic.bool),
    dynamic.field("position", dynamic.int),
  )(dyn)
}

pub fn attempt_decoder(dyn: Dynamic) -> Result(QuizAttempt, List(DecodeError)) {
  dynamic.decode7(
    QuizAttempt,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("user_key", dynamic.string),
    dynamic.field("quiz_key", dynamic.string),
    dynamic.optional_field("score", dynamic.float),
    dynamic.field("started_at", dynamic.string),
    dynamic.optional_field("completed_at", dynamic.string),
    dynamic.optional_field("passed", dynamic.bool),
  )(dyn)
}

pub fn answer_decoder(dyn: Dynamic) -> Result(QuizAnswer, List(DecodeError)) {
  dynamic.decode7(
    QuizAnswer,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("attempt_key", dynamic.string),
    dynamic.field("question_key", dynamic.string),
    dynamic.optional_field("option_key", dynamic.string),
    dynamic.optional_field("answer_text", dynamic.string),
    dynamic.optional_field("is_correct", dynamic.bool),
    dynamic.field("points_earned", dynamic.int),
  )(dyn)
}

pub fn quiz_to_json(quiz: Quiz) -> Json {
  json.object([
    #("course_key", json.string(quiz.course_key)),
    #("title", json.string(quiz.title)),
    #("description", case quiz.description {
      Some(d) -> json.string(d)
      None -> json.null()
    }),
    #("passing_score", json.int(quiz.passing_score)),
    #("time_limit_minutes", case quiz.time_limit_minutes {
      Some(t) -> json.int(t)
      None -> json.null()
    }),
    #("quiz_type", json.string(quiz_type_to_string(quiz.quiz_type))),
    #("published", json.bool(quiz.published)),
    #("max_attempts", case quiz.max_attempts {
      Some(m) -> json.int(m)
      None -> json.null()
    }),
  ])
}

pub fn question_to_json(q: Question) -> Json {
  json.object([
    #("content", json.string(q.content)),
    #("explanation", case q.explanation {
      Some(e) -> json.string(e)
      None -> json.null()
    }),
    #("difficulty", json.int(q.difficulty)),
    #("category_key", json.string(q.category_key)),
    #("question_type", json.string(question_type_to_string(q.question_type))),
    #("points", json.int(q.points)),
    #("image_url", case q.image_url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

pub fn attempt_to_json(a: QuizAttempt) -> Json {
  json.object([
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
