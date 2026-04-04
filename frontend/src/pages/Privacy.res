// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (): Html.t<'msg> => {
  div([class'("legal-page")], [
    div([class'("container")], [
      h1([class'("page-title")], [text("Privacy Policy")]),
      div([class'("legal-content")], [
        section([class'("legal-section")], [
          h2([], [text("1. Information We Collect")]),
          p([], [
            text("We collect information you provide directly, including your email address when you create an account, "),
            text("and training performance data to personalize your learning experience."),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("2. How We Use Your Information")]),
          p([], [text("Your information is used to:")]),
          ul([], [
            li([], [text("Provide and improve our training services")]),
            li([], [text("Track your learning progress and competence development")]),
            li([], [text("Personalize training difficulty and content")]),
            li([], [text("Send important service notifications")]),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("3. Data Security")]),
          p([], [
            text("We implement appropriate security measures to protect your personal information. "),
            text("Training data is stored securely and encrypted in transit."),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("4. Data Retention")]),
          p([], [
            text("We retain your account and training data as long as your account is active. "),
            text("You may request deletion of your data by contacting us."),
          ]),
        ]),
        section([class'("legal-section")], [
          h2([], [text("5. Contact")]),
          p([], [
            text("For privacy-related inquiries, please contact us at privacy@hyperpolymath.com."),
          ]),
        ]),
      ]),
      p([class'("legal-updated")], [text("Last updated: January 2025")]),
    ]),
  ])
}
