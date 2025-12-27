// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (
  course: Types.courseDetail,
  auth: Main.authState,
  toMsg: Main.msg => 'msg,
): Html.t<'msg> => {
  div([class'("course-detail-page")], [
    div([class'("course-header")], [
      div([class'("container")], [
        h1([class'("course-title")], [text(course.title)]),
        switch course.description {
        | Some(desc) => p([class'("course-description")], [text(desc)])
        | None => noNode
        },
        div([class'("course-meta")], [
          span([class'("meta-item")], [text("Level: " ++ course.level)]),
          span([class'("meta-item")], [
            text("Duration: " ++ Belt.Int.toString(course.durationHours) ++ " hours"),
          ]),
          switch course.instructor {
          | Some(instructor) =>
            span([class'("meta-item")], [text("Instructor: " ++ instructor.email)])
          | None => noNode
          },
          switch course.category {
          | Some(cat) => span([class'("meta-item")], [text("Category: " ++ cat.name)])
          | None => noNode
          },
        ]),
        div([class'("course-price")], [
          text(
            if course.price == 0.0 {
              "Free"
            } else {
              "$" ++ Belt.Float.toString(course.price)
            },
          ),
        ]),
        switch auth {
        | Main.Authenticated(_) =>
          button(
            [class'("btn btn-primary btn-large"), onClick(toMsg(Main.EnrollClicked(course.key)))],
            [text("Enroll Now")],
          )
        | _ =>
          a(
            [href("/login"), class'("btn btn-primary btn-large")],
            [text("Login to Enroll")],
          )
        },
      ]),
    ]),
    div([class'("course-content")], [
      div([class'("container")], [
        h2([class'("section-title")], [text("Course Content")]),
        div(
          [class'("modules-list")],
          course.modules->Belt.Array.map(mod => {
            div([class'("module-card")], [
              h3([class'("module-title")], [text(mod.title)]),
              switch mod.description {
              | Some(desc) => p([class'("module-description")], [text(desc)])
              | None => noNode
              },
              ul(
                [class'("lessons-list")],
                mod.lessons->Belt.Array.map(lesson => {
                  li([class'("lesson-item")], [
                    span([class'("lesson-type")], [text(lesson.lessonType)]),
                    span([class'("lesson-title")], [text(lesson.title)]),
                    span([class'("lesson-duration")], [
                      text(Belt.Int.toString(lesson.durationMinutes) ++ " min"),
                    ]),
                  ])
                }),
              ),
            ])
          }),
        ),
        if Belt.Array.length(course.quizzes) > 0 {
          div([class'("quizzes-section")], [
            h2([class'("section-title")], [text("Quizzes")]),
            ul(
              [class'("quizzes-list")],
              course.quizzes->Belt.Array.map(quiz => {
                li([class'("quiz-item")], [
                  span([class'("quiz-title")], [text(quiz.title)]),
                  span([class'("quiz-type")], [text(quiz.quizType)]),
                  span([class'("quiz-passing")], [
                    text("Passing: " ++ Belt.Int.toString(quiz.passingScore) ++ "%"),
                  ]),
                ])
              }),
            ),
          ])
        } else {
          noNode
        },
      ]),
    ]),
  ])
}
