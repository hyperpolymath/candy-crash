// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("auth-page")], [
    div([class'("auth-container")], [
      h1([class'("auth-title")], [text("Login")]),
      form(
        [class'("auth-form"), onSubmit(toMsg(Main.LoginSubmit("", "")))],
        [
          div([class'("form-group")], [
            label([for'("email")], [text("Email")]),
            input'(
              [
                type'("email"),
                id("email"),
                name("email"),
                placeholder("Enter your email"),
                class'("form-input"),
                Attributes.required(true),
              ],
              [],
            ),
          ]),
          div([class'("form-group")], [
            label([for'("password")], [text("Password")]),
            input'(
              [
                type'("password"),
                id("password"),
                name("password"),
                placeholder("Enter your password"),
                class'("form-input"),
                Attributes.required(true),
              ],
              [],
            ),
          ]),
          button([type'("submit"), class'("btn btn-primary btn-block")], [text("Login")]),
        ],
      ),
      div([class'("auth-footer")], [
        p([], [
          text("Don't have an account? "),
          a([href("/register")], [text("Sign up")]),
        ]),
        p([], [a([href("/forgot-password")], [text("Forgot password?")])]),
      ]),
    ]),
  ])
}
