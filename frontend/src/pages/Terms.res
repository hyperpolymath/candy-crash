// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (): Html.t<'msg> => {
  div([class'("legal-page")], [
    div([class'("container")], [
      h1([class'("page-title")], [text("Terms of Service")]),
      div([class'("legal-content")], [
        section([class'("legal-section")], [
          h2([], [text("1. Acceptance of Terms")]),
          p([], [
            text("By accessing or using Candy Crash, you agree to be bound by these Terms of Service. "),
            text("If you do not agree to these terms, please do not use our services."),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("2. Description of Service")]),
          p([], [
            text("Candy Crash is a vehicle operator training platform that provides perceptual learning "),
            text("and skill development through adaptive training exercises."),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("3. User Accounts")]),
          p([], [text("You are responsible for:")]),
          ul([], [
            li([], [text("Maintaining the confidentiality of your account credentials")]),
            li([], [text("All activities that occur under your account")]),
            li([], [text("Providing accurate account information")]),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("4. Acceptable Use")]),
          p([], [text("You agree not to:")]),
          ul([], [
            li([], [text("Use the service for any unlawful purpose")]),
            li([], [text("Attempt to interfere with or disrupt the service")]),
            li([], [text("Share your account with others")]),
            li([], [text("Misrepresent your training results or competence levels")]),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("5. Disclaimer")]),
          p([], [
            text("Training on this platform is supplementary and does not replace formal driver training or certification. "),
            text("We make no guarantees about real-world driving performance."),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("6. Changes to Terms")]),
          p([], [
            text("We may modify these terms at any time. Continued use of the service after changes "),
            text("constitutes acceptance of the modified terms."),
          ]),
        ]),
      ]),
      p([class'("legal-updated")], [text("Last updated: January 2025")]),
    ]),
  ])
}
