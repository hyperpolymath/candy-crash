// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (): Html.t<'msg> => {
  div([class'("not-found-page")], [
    div([class'("container")], [
      h1([class'("error-code")], [text("404")]),
      h2([class'("error-message")], [text("Page Not Found")]),
      p([class'("error-description")], [
        text("The page you're looking for doesn't exist or has been moved."),
      ]),
      a([href("/"), class'("btn btn-primary")], [text("Go Home")]),
    ]),
  ])
}
