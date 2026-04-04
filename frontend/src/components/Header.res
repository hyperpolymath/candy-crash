// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (auth: Main.authState, toMsg: Main.msg => 'msg): Html.t<'msg> => {
  header([class'("header")], [
    div([class'("header-container")], [
      a([href("/"), class'("logo")], [text("Candy Crash")]),
      nav([class'("nav")], [
        a([href("/courses"), class'("nav-link")], [text("Courses")]),
        a([href("/demo"), class'("nav-link")], [text("Demo")]),
        a([href("/about"), class'("nav-link")], [text("About")]),
      ]),
      div([class'("auth-nav")], [
        switch auth {
        | Main.Anonymous => {
            fragment([
              a([href("/login"), class'("btn btn-outline")], [text("Login")]),
              a([href("/register"), class'("btn btn-primary")], [text("Sign Up")]),
            ])
          }
        | Main.Loading => span([class'("loading-text")], [text("Loading...")])
        | Main.Authenticated(user) => {
            fragment([
              a([href("/dashboard"), class'("nav-link")], [text("Dashboard")]),
              a([href("/training"), class'("nav-link")], [text("Training")]),
              span([class'("user-email")], [text(user.email)]),
              button(
                [class'("btn btn-outline"), onClick(toMsg(Main.LogoutClicked))],
                [text("Logout")],
              ),
            ])
          }
        },
      ]),
    ]),
  ])
}
