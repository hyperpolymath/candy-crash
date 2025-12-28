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
        // My Courses card
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

        // Training card - new!
        div([class'("dashboard-card training-card")], [
          h3([class'("card-title")], [text("Skill Training")]),
          div([class'("training-promo")], [
            div([class'("promo-icon")], [text("🎯")]),
            p([], [text("Develop your perception skills with adaptive training exercises.")]),
            div([class'("training-actions")], [
              a([href("/training"), class'("btn btn-primary")], [text("Start Training")]),
              a([href("/demo"), class'("btn btn-outline")], [text("Try Demo")]),
            ]),
          ]),
        ]),

        // Recent Activity card
        div([class'("dashboard-card")], [
          h3([class'("card-title")], [text("Recent Activity")]),
          div([class'("activity-list")], [
            div([class'("activity-item")], [
              span([class'("activity-icon")], [text("📚")]),
              span([class'("activity-text")], [text("Your training sessions will appear here")]),
            ]),
          ]),
          a([href("/training"), class'("card-link")], [text("View all activity →")]),
        ]),

        // Achievements card
        div([class'("dashboard-card")], [
          h3([class'("card-title")], [text("Achievements")]),
          div([class'("achievements-preview")], [
            div([class'("achievement-placeholder")], [
              span([class'("placeholder-icon")], [text("🏆")]),
              p([], [text("Complete training sessions to earn achievements")]),
            ]),
          ]),
        ]),

        // Statistics card
        div([class'("dashboard-card stats")], [
          h3([class'("card-title")], [text("Statistics")]),
          div([class'("stats-grid")], [
            div([class'("stat-item")], [
              span([class'("stat-value")], [text(Belt.Int.toString(Belt.Array.length(enrollments)))]),
              span([class'("stat-label")], [text("Courses")]),
            ]),
            div([class'("stat-item")], [
              span([class'("stat-value")], [text("—")]),
              span([class'("stat-label")], [text("Lessons")]),
            ]),
            div([class'("stat-item")], [
              span([class'("stat-value")], [text("—")]),
              span([class'("stat-label")], [text("Training Sessions")]),
            ]),
            div([class'("stat-item")], [
              span([class'("stat-value")], [text("—")]),
              span([class'("stat-label")], [text("Competence")]),
            ]),
          ]),
        ]),
      ]),
    ]),
  ])
}
