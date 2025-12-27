// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (lesson: Types.lesson, courseId: string, toMsg: Main.msg => 'msg): Html.t<'msg> => {
  div([class'("lesson-page")], [
    div([class'("lesson-header")], [
      div([class'("container")], [
        div([class'("lesson-nav")], [
          switch lesson.prevLesson {
          | Some(prevId) =>
            a(
              [
                href("/courses/" ++ courseId ++ "/lessons/" ++ prevId),
                class'("btn btn-outline"),
              ],
              [text("Previous Lesson")],
            )
          | None => noNode
          },
          switch lesson.nextLesson {
          | Some(nextId) =>
            a(
              [
                href("/courses/" ++ courseId ++ "/lessons/" ++ nextId),
                class'("btn btn-outline"),
              ],
              [text("Next Lesson")],
            )
          | None => noNode
          },
        ]),
        h1([class'("lesson-title")], [text(lesson.title)]),
        div([class'("lesson-meta")], [
          span([class'("meta-item")], [text("Type: " ++ lesson.lessonType)]),
          span([class'("meta-item")], [
            text("Duration: " ++ Belt.Int.toString(lesson.durationMinutes) ++ " min"),
          ]),
          switch lesson.progress {
          | Some(p) =>
            if p.completed {
              span([class'("meta-item completed")], [text("Completed")])
            } else {
              noNode
            }
          | None => noNode
          },
        ]),
      ]),
    ]),
    div([class'("lesson-content")], [
      div([class'("container")], [
        switch lesson.videoUrl {
        | Some(url) =>
          div([class'("video-container")], [
            video([src(url), Attributes.controls(true), class'("lesson-video")], []),
          ])
        | None => noNode
        },
        switch lesson.content {
        | Some(content) =>
          div([class'("lesson-text")], [
            // In a real app, you'd render markdown here
            p([], [text(content)]),
          ])
        | None => noNode
        },
        div([class'("lesson-actions")], [
          switch lesson.progress {
          | Some(p) =>
            if p.completed {
              span([class'("completed-badge")], [text("Lesson Completed")])
            } else {
              button(
                [
                  class'("btn btn-primary"),
                  onClick(toMsg(Main.CompleteLessonClicked(courseId, lesson.key))),
                ],
                [text("Mark as Complete")],
              )
            }
          | None =>
            button(
              [
                class'("btn btn-primary"),
                onClick(toMsg(Main.CompleteLessonClicked(courseId, lesson.key))),
              ],
              [text("Mark as Complete")],
            )
          },
        ]),
      ]),
    ]),
  ])
}
