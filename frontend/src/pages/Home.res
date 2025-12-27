// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (courses: array<Types.course>, toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("home-page")], [
    section([class'("hero")], [
      div([class'("hero-content")], [
        h1([class'("hero-title")], [text("Learn Something New Today")]),
        p([class'("hero-subtitle")], [
          text("Discover courses that will help you grow your skills and advance your career"),
        ]),
        a(
          [
            href("/courses"),
            class'("btn btn-primary btn-large"),
            onClick(toMsg(Main.NavigateTo(Main.Courses))),
          ],
          [text("Browse Courses")],
        ),
      ]),
    ]),
    section([class'("featured-courses")], [
      div([class'("container")], [
        h2([class'("section-title")], [text("Featured Courses")]),
        div(
          [class'("course-grid")],
          courses
          ->Belt.Array.slice(~offset=0, ~len=6)
          ->Belt.Array.map(course => Components.CourseCard.view(course, toMsg)),
        ),
        div([class'("view-all")], [
          a(
            [
              href("/courses"),
              class'("btn btn-outline"),
              onClick(toMsg(Main.NavigateTo(Main.Courses))),
            ],
            [text("View All Courses")],
          ),
        ]),
      ]),
    ]),
    section([class'("features")], [
      div([class'("container")], [
        h2([class'("section-title")], [text("Why Learn With Us?")]),
        div([class'("features-grid")], [
          div([class'("feature-card")], [
            div([class'("feature-icon")], [text("Interactive")]),
            h3([], [text("Interactive Lessons")]),
            p([], [text("Engage with hands-on exercises and real-world projects")]),
          ]),
          div([class'("feature-card")], [
            div([class'("feature-icon")], [text("Quiz")]),
            h3([], [text("Knowledge Checks")]),
            p([], [text("Test your understanding with quizzes and assessments")]),
          ]),
          div([class'("feature-card")], [
            div([class'("feature-icon")], [text("Badge")]),
            h3([], [text("Earn Achievements")]),
            p([], [text("Track your progress and collect badges as you learn")]),
          ]),
          div([class'("feature-card")], [
            div([class'("feature-icon")], [text("Certificate")]),
            h3([], [text("Get Certified")]),
            p([], [text("Receive certificates upon course completion")]),
          ]),
        ]),
      ]),
    ]),
  ])
}
