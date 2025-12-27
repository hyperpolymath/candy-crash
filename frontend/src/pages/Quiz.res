// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (courseId: string, quizId: string, toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("quiz-page")], [
    div([class'("container")], [
      h1([class'("page-title")], [text("Quiz")]),
      p([], [text("Quiz ID: " ++ quizId)]),
      p([], [text("Course ID: " ++ courseId)]),
      div([class'("quiz-placeholder")], [
        p([], [text("Quiz functionality coming soon...")]),
        a(
          [href("/courses/" ++ courseId), class'("btn btn-outline")],
          [text("Back to Course")],
        ),
      ]),
    ]),
  ])
}
