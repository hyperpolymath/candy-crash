// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

let view = (error: string, onDismiss: 'msg): Html.t<'msg> => {
  div([class'("error-banner")], [
    span([class'("error-message")], [text(error)]),
    button([class'("error-dismiss"), onClick(onDismiss)], [text("Dismiss")]),
  ])
}
