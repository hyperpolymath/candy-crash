// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (course: Types.course, toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("course-card")], [
    switch course.thumbnailUrl {
    | Some(url) => img([src(url), alt(course.title), class'("course-thumbnail")])
    | None => div([class'("course-thumbnail placeholder")], [])
    },
    div([class'("course-card-content")], [
      h3([class'("course-title")], [text(course.title)]),
      switch course.description {
      | Some(desc) => p([class'("course-description")], [text(desc)])
      | None => noNode
      },
      div([class'("course-meta")], [
        span([class'("course-level")], [text(course.level)]),
        span([class'("course-duration")], [text(Belt.Int.toString(course.durationHours) ++ " hours")]),
        span([class'("course-price")], [
          text(
            if course.price == 0.0 {
              "Free"
            } else {
              "$" ++ Belt.Float.toString(course.price)
            },
          ),
        ]),
      ]),
      a(
        [
          href("/courses/" ++ course.key),
          class'("btn btn-primary"),
          onClick(toMsg(Main.NavigateTo(Main.CourseDetail(course.key)))),
        ],
        [text("View Course")],
      ),
    ]),
  ])
}
