// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (courses: array<Types.course>, toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("courses-page")], [
    div([class'("container")], [
      h1([class'("page-title")], [text("Courses")]),
      div([class'("courses-filters")], [
        div([class'("search-box")], [
          input'([type'("text"), placeholder("Search courses..."), class'("search-input")], []),
        ]),
        div([class'("filter-group")], [
          select([class'("filter-select")], [
            option([value("")], [text("All Categories")]),
          ]),
          select([class'("filter-select")], [
            option([value("")], [text("All Levels")]),
            option([value("beginner")], [text("Beginner")]),
            option([value("intermediate")], [text("Intermediate")]),
            option([value("advanced")], [text("Advanced")]),
          ]),
        ]),
      ]),
      if Belt.Array.length(courses) == 0 {
        div([class'("no-courses")], [
          p([], [text("No courses found. Check back later!")]),
        ])
      } else {
        div(
          [class'("course-grid")],
          courses->Belt.Array.map(course => Components.CourseCard.view(course, toMsg)),
        )
      },
    ]),
  ])
}
