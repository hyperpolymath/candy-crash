// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("auth-page")], [
    div([class'("auth-container")], [
      h1([class'("auth-title")], [text("Create Account")]),
      form(
        [class'("auth-form"), onSubmit(toMsg(Main.RegisterSubmit("", "", "student")))],
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
                placeholder("Create a password"),
                class'("form-input"),
                Attributes.required(true),
                Attributes.min("8"),
              ],
              [],
            ),
          ]),
          div([class'("form-group")], [
            label([for'("confirm-password")], [text("Confirm Password")]),
            input'(
              [
                type'("password"),
                id("confirm-password"),
                name("confirm-password"),
                placeholder("Confirm your password"),
                class'("form-input"),
                Attributes.required(true),
              ],
              [],
            ),
          ]),
          button([type'("submit"), class'("btn btn-primary btn-block")], [text("Sign Up")]),
        ],
      ),
      div([class'("auth-footer")], [
        p([], [
          text("Already have an account? "),
          a([href("/login")], [text("Login")]),
        ]),
      ]),
    ]),
  ])
}
