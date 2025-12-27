// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (): Html.t<'msg> => {
  footer([class'("footer")], [
    div([class'("footer-container")], [
      div([class'("footer-section")], [
        h4([], [text("Candy Crash")]),
        p([], [text("Learn with joy, grow with knowledge")]),
      ]),
      div([class'("footer-section")], [
        h4([], [text("Links")]),
        ul([], [
          li([], [a([href("/courses")], [text("Courses")])]),
          li([], [a([href("/about")], [text("About")])]),
        ]),
      ]),
      div([class'("footer-section")], [
        h4([], [text("Legal")]),
        ul([], [
          li([], [a([href("/privacy")], [text("Privacy Policy")])]),
          li([], [a([href("/terms")], [text("Terms of Service")])]),
        ]),
      ]),
    ]),
    div([class'("footer-bottom")], [
      p([], [text("2025 Hyperpolymath. MIT License.")]),
    ]),
  ])
}
