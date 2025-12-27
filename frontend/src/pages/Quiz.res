// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

// Quiz view - shows quiz info and placeholder for full functionality
// Full quiz taking requires Main.res integration (state, messages, handlers)
let view = (courseId: string, quizId: string, _toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("quiz-page")], [
    div([class'("container")], [
      div([class'("quiz-info")], [
        h1([class'("page-title")], [text("Quiz")]),
        p([class'("quiz-description")], [
          text("Quiz ID: " ++ quizId),
        ]),
        div([class'("quiz-meta")], [
          div([class'("meta-item")], [
            span([class'("meta-label")], [text("Course")]),
            span([class'("meta-value")], [text(courseId)]),
          ]),
          div([class'("meta-item")], [
            span([class'("meta-label")], [text("Status")]),
            span([class'("meta-value")], [text("Ready")]),
          ]),
        ]),
        div([class'("quiz-notice")], [
          p([], [
            text("The full quiz experience is being integrated. "),
            text("Please check back soon!"),
          ]),
        ]),
        div([class'("quiz-actions")], [
          a([
            href("/courses/" ++ courseId),
            class'("btn btn-primary"),
          ], [text("Back to Course")]),
        ]),
      ]),
    ]),
  ])
}
