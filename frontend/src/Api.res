// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Cmd

let apiUrl = "http://localhost:4000/api"

// Token management (minimal JS interop)
@val @scope("localStorage") external getItem: string => Js.Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"
@val @scope("localStorage") external removeItem: string => unit = "removeItem"

let getToken = (): option<string> => {
  getItem("token")->Js.Nullable.toOption
}

let setToken = (token: string): unit => {
  setItem("token", token)
}

let clearToken = (): unit => {
  removeItem("token")
}

// Fetch helpers
type fetchError = string

external jsonParse: string => 'a = "JSON.parse"

let makeHeaders = (): array<(string, string)> => {
  let base = [("Content-Type", "application/json")]
  switch getToken() {
  | Some(token) => Belt.Array.concat(base, [("Authorization", "Bearer " ++ token)])
  | None => base
  }
}

// API functions
let fetchCourses = (toMsg: result<array<Types.course>, string> => 'msg): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let _ = Fetch.fetch(apiUrl ++ "/courses")
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      let courses = json["courses"]
      callbacks.enqueue(toMsg(Ok(courses)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to fetch courses")))
      Js.Promise.resolve()
    }, _)
  })
}

let fetchCourse = (id: string, toMsg: result<Types.courseDetail, string> => 'msg): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let _ = Fetch.fetch(apiUrl ++ "/courses/" ++ id)
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      callbacks.enqueue(toMsg(Ok(json)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to fetch course")))
      Js.Promise.resolve()
    }, _)
  })
}

let fetchLesson = (
  courseId: string,
  lessonId: string,
  toMsg: result<Types.lesson, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let url = apiUrl ++ "/courses/" ++ courseId ++ "/lessons/" ++ lessonId
    let _ = Fetch.fetchWithInit(
      url,
      Fetch.RequestInit.make(~headers=Fetch.HeadersInit.makeWithArray(makeHeaders()), ()),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      callbacks.enqueue(toMsg(Ok(json)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to fetch lesson")))
      Js.Promise.resolve()
    }, _)
  })
}

let login = (
  email: string,
  password: string,
  toMsg: result<Main.user, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let body = Js.Json.stringifyAny({"email": email, "password": password})->Belt.Option.getExn
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/auth/login",
      Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Fetch.HeadersInit.makeWithArray([("Content-Type", "application/json")]),
        ~body=Fetch.BodyInit.make(body),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      let token = json["token"]
      setToken(token)
      let user = json["user"]
      callbacks.enqueue(toMsg(Ok(user)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Login failed")))
      Js.Promise.resolve()
    }, _)
  })
}

let register = (
  email: string,
  password: string,
  toMsg: result<Main.user, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let body =
      Js.Json.stringifyAny({"email": email, "password": password, "role": "student"})->Belt.Option.getExn
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/auth/register",
      Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Fetch.HeadersInit.makeWithArray([("Content-Type", "application/json")]),
        ~body=Fetch.BodyInit.make(body),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      let token = json["token"]
      setToken(token)
      let user = json["user"]
      callbacks.enqueue(toMsg(Ok(user)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Registration failed")))
      Js.Promise.resolve()
    }, _)
  })
}

let enroll = (courseId: string, toMsg: result<Types.enrollment, string> => 'msg): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/enrollments/enroll/" ++ courseId,
      Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Fetch.HeadersInit.makeWithArray(makeHeaders()),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      let enrollment = json["enrollment"]
      callbacks.enqueue(toMsg(Ok(enrollment)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Enrollment failed")))
      Js.Promise.resolve()
    }, _)
  })
}

let completeLesson = (
  courseId: string,
  lessonId: string,
  toMsg: result<Types.lessonProgress, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let url = apiUrl ++ "/courses/" ++ courseId ++ "/lessons/" ++ lessonId ++ "/complete"
    let _ = Fetch.fetchWithInit(
      url,
      Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Fetch.HeadersInit.makeWithArray(makeHeaders()),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      callbacks.enqueue(toMsg(Ok(json)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to complete lesson")))
      Js.Promise.resolve()
    }, _)
  })
}
