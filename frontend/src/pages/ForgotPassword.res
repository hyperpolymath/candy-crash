// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

type forgotPasswordState =
  | Ready
  | Submitting
  | Sent
  | Error(string)

let view = (
  email: string,
  state: forgotPasswordState,
  onEmailChange: string => 'msg,
  onSubmit: unit => 'msg,
): Html.t<'msg> => {
  div([class'("auth-page")], [
    div([class'("auth-container")], [
      h1([class'("auth-title")], [text("Reset Password")]),
      switch state {
      | Sent =>
        div([class'("success-message")], [
          div([class'("success-icon")], [text("✓")]),
          h2([], [text("Check Your Email")]),
          p([], [
            text("If an account exists with that email address, we've sent password reset instructions."),
          ]),
          p([class'("hint")], [
            text("Check your spam folder if you don't see the email within a few minutes."),
          ]),
          a([href("/login"), class'("btn btn-primary")], [text("Back to Login")]),
        ])
      | _ =>
        form(
          [
            class'("auth-form"),
            onSubmit(onSubmit()),
          ],
          [
            p([class'("auth-description")], [
              text("Enter your email address and we'll send you a link to reset your password."),
            ]),
            div([class'("form-group")], [
              label([for'("email")], [text("Email")]),
              input'(
                [
                  type'("email"),
                  id("email"),
                  value(email),
                  onInput(e => onEmailChange(e)),
                  placeholder("Enter your email"),
                  required(true),
                  disabled(state == Submitting),
                ],
                [],
              ),
            ]),
            switch state {
            | Error(message) =>
              div([class'("error-message")], [text(message)])
            | _ => noNode
            },
            button(
              [
                type'("submit"),
                class'("btn btn-primary btn-block"),
                disabled(state == Submitting),
              ],
              [
                text(
                  switch state {
                  | Submitting => "Sending..."
                  | _ => "Send Reset Link"
                  },
                ),
              ],
            ),
            p([class'("auth-footer")], [
              text("Remember your password? "),
              a([href("/login")], [text("Login")]),
            ]),
          ],
        )
      },
    ]),
  ])
}
