// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (): Html.t<'msg> => {
  div([class'("about-page")], [
    div([class'("container")], [
      h1([class'("page-title")], [text("About Candy Crash")]),
      div([class'("about-content")], [
        section([class'("about-section")], [
          h2([], [text("Our Mission")]),
          p([], [
            text(
              "Candy Crash is an e-learning platform designed to make education accessible, engaging, and fun. We believe that everyone deserves the opportunity to learn and grow, regardless of their background or circumstances.",
            ),
          ]),
        ]),
        section([class'("about-section")], [
          h2([], [text("What We Offer")]),
          ul([class'("features-list")], [
            li([], [text("Interactive courses across multiple disciplines")]),
            li([], [text("Hands-on projects and real-world exercises")]),
            li([], [text("Knowledge assessments and quizzes")]),
            li([], [text("Achievement system to track your progress")]),
            li([], [text("Expert instructors from around the world")]),
          ]),
        ]),
        section([class'("about-section")], [
          h2([], [text("Technology")]),
          p([], [
            text(
              "Built with modern, sustainable technology following the Hyperpolymath Standard. Our platform uses Gleam for the backend, ReScript for the frontend, and ArangoDB for data storage - all free and open-source technologies.",
            ),
          ]),
        ]),
        section([class'("about-section")], [
          h2([], [text("Open Source")]),
          p([], [
            text(
              "Candy Crash is open source software released under the MIT license. We believe in transparency, collaboration, and community-driven development.",
            ),
          ]),
        ]),
      ]),
    ]),
  ])
}
