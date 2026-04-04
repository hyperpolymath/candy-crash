// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Sub

// Browser history API bindings
@val @scope(("window", "location")) external pathname: string = "pathname"
@val @scope(("window", "location")) external search: string = "search"
@val @scope(("window", "history"))
external pushState: (Js.Nullable.t<'a>, string, string) => unit = "pushState"
@val @scope(("window", "history"))
external replaceState: (Js.Nullable.t<'a>, string, string) => unit = "replaceState"

let getPath = (): string => pathname

let getQuery = (): string => search

let pushPath = (path: string): unit => {
  pushState(Js.Nullable.null, "", path)
  // Dispatch popstate event to trigger subscription
  let _ = %raw(`
    window.dispatchEvent(new PopStateEvent('popstate', { state: null }))
  `)
}

let replacePath = (path: string): unit => {
  replaceState(Js.Nullable.null, "", path)
}

// URL change subscription
let onUrlChange = (toMsg: string => 'msg): Sub.t<'msg> => {
  Sub.registration(
    "url-change",
    callbacks => {
      let handler = _event => {
        callbacks.enqueue(toMsg(getPath()))
      }

      // Add event listener
      let _ = %raw(`window.addEventListener('popstate', handler)`)

      // Return cleanup function
      () => {
        let _ = %raw(`window.removeEventListener('popstate', handler)`)
      }
    },
  )
}

// Parse query parameters
let parseQuery = (query: string): Belt.Map.String.t<string> => {
  if query == "" || query == "?" {
    Belt.Map.String.empty
  } else {
    let queryString = if Js.String2.startsWith(query, "?") {
      Js.String2.substr(query, ~from=1)
    } else {
      query
    }

    queryString
    ->Js.String2.split("&")
    ->Belt.Array.reduce(Belt.Map.String.empty, (acc, pair) => {
      switch Js.String2.split(pair, "=") {
      | [key, value] => Belt.Map.String.set(acc, key, Js.Global.decodeURIComponent(value))
      | [key] => Belt.Map.String.set(acc, key, "")
      | _ => acc
      }
    })
  }
}

// Build query string
let buildQuery = (params: Belt.Map.String.t<string>): string => {
  let pairs =
    params
    ->Belt.Map.String.toArray
    ->Belt.Array.map(((key, value)) => {
      key ++ "=" ++ Js.Global.encodeURIComponent(value)
    })

  if Belt.Array.length(pairs) == 0 {
    ""
  } else {
    "?" ++ Js.Array2.joinWith(pairs, "&")
  }
}
