// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (): Html.t<'msg> => {
  div([class'("loading-container")], [
    div([class'("loading-spinner")], []),
    p([class'("loading-text")], [text("Loading...")]),
  ])
}
