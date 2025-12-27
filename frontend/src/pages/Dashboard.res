// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (user: Main.user, enrollments: array<Types.enrollment>): Html.t<'msg> => {
  div([class'("dashboard-page")], [
    div([class'("container")], [
      h1([class'("page-title")], [text("Dashboard")]),
      div([class'("dashboard-header")], [
        div([class'("user-info")], [
          h2([], [text("Welcome back!")]),
          p([], [text(user.email)]),
          span([class'("role-badge")], [text(user.role)]),
        ]),
      ]),
      div([class'("dashboard-grid")], [
        div([class'("dashboard-card")], [
          h3([class'("card-title")], [text("My Courses")]),
          if Belt.Array.length(enrollments) == 0 {
            div([class'("empty-state")], [
              p([], [text("You haven't enrolled in any courses yet.")]),
              a([href("/courses"), class'("btn btn-primary")], [text("Browse Courses")]),
            ])
          } else {
            ul(
              [class'("enrollments-list")],
              enrollments->Belt.Array.map(enrollment => {
                li([class'("enrollment-item")], [
                  div([class'("enrollment-info")], [
                    span([class'("course-key")], [text(enrollment.courseKey)]),
                    div([class'("progress-bar")], [
                      div(
                        [
                          class'("progress-fill"),
                          style("width", Belt.Int.toString(enrollment.progress) ++ "%"),
                        ],
                        [],
                      ),
                    ]),
                    span([class'("progress-text")], [
                      text(Belt.Int.toString(enrollment.progress) ++ "% complete"),
                    ]),
                  ]),
                  span([class'("status-badge " ++ enrollment.status)], [text(enrollment.status)]),
                ])
              }),
            )
          },
        ]),
        div([class'("dashboard-card")], [
          h3([class'("card-title")], [text("Recent Activity")]),
          p([class'("placeholder-text")], [text("Your recent quiz attempts and lessons will appear here.")]),
        ]),
        div([class'("dashboard-card")], [
          h3([class'("card-title")], [text("Achievements")]),
          p([class'("placeholder-text")], [text("Your earned badges and achievements will appear here.")]),
        ]),
        div([class'("dashboard-card stats")], [
          h3([class'("card-title")], [text("Statistics")]),
          div([class'("stats-grid")], [
            div([class'("stat-item")], [
              span([class'("stat-value")], [text(Belt.Int.toString(Belt.Array.length(enrollments)))]),
              span([class'("stat-label")], [text("Courses")]),
            ]),
            div([class'("stat-item")], [
              span([class'("stat-value")], [text("0")]),
              span([class'("stat-label")], [text("Lessons")]),
            ]),
            div([class'("stat-item")], [
              span([class'("stat-value")], [text("0")]),
              span([class'("stat-label")], [text("Quizzes")]),
            ]),
            div([class'("stat-item")], [
              span([class'("stat-value")], [text("0")]),
              span([class'("stat-label")], [text("Points")]),
            ]),
          ]),
        ]),
      ]),
    ]),
  ])
}
