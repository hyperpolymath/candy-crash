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

let forgotPassword = (
  email: string,
  toMsg: result<string, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let body = Js.Json.stringifyAny({"email": email})->Belt.Option.getExn
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/auth/forgot-password",
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
      let message = json["message"]
      callbacks.enqueue(toMsg(Ok(message)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to send reset email")))
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

// Training Loop API

let fetchTrainingSkills = (toMsg: result<array<Types.microSkill>, string> => 'msg): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let _ = Fetch.fetch(apiUrl ++ "/training/skills")
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      let skills = json["skills"]
      callbacks.enqueue(toMsg(Ok(skills)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to fetch training skills")))
      Js.Promise.resolve()
    }, _)
  })
}

type startSessionResponse = {
  session: Types.trainingSession,
  traineeState: Types.traineeState,
}

let startTrainingSession = (
  activity: string,
  domain: string,
  toMsg: result<startSessionResponse, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let body = Js.Json.stringifyAny({"activity": activity, "domain": domain})->Belt.Option.getExn
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/training/session/start",
      Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Fetch.HeadersInit.makeWithArray(makeHeaders()),
        ~body=Fetch.BodyInit.make(body),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      callbacks.enqueue(toMsg(Ok({
        session: json["session"],
        traineeState: json["trainee_state"],
      })))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to start training session")))
      Js.Promise.resolve()
    }, _)
  })
}

type nextInterventionResponse =
  | Intervention(Types.intervention)
  | Wait(int, string)
  | SessionComplete(string)

let getNextIntervention = (
  sessionId: string,
  toMsg: result<nextInterventionResponse, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/training/session/" ++ sessionId ++ "/next",
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
      let response = if Js.typeof(json["intervention"]) != "undefined" {
        Intervention(json["intervention"])
      } else if json["session_complete"] == true {
        SessionComplete(json["message"])
      } else {
        Wait(json["wait_ms"], json["message"])
      }
      callbacks.enqueue(toMsg(Ok(response)))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to get next intervention")))
      Js.Promise.resolve()
    }, _)
  })
}

let respondToIntervention = (
  interventionId: string,
  sessionId: string,
  responseTimeMs: int,
  toMsg: result<Types.interventionResponse, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let body = Js.Json.stringifyAny({
      "response_time_ms": responseTimeMs,
      "session_id": sessionId,
    })->Belt.Option.getExn
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/training/intervention/" ++ interventionId ++ "/respond",
      Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Fetch.HeadersInit.makeWithArray(makeHeaders()),
        ~body=Fetch.BodyInit.make(body),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      callbacks.enqueue(toMsg(Ok({
        outcome: json["outcome"],
        newCompetence: json["new_competence"],
        feedback: json["feedback"],
      })))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to submit response")))
      Js.Promise.resolve()
    }, _)
  })
}

type endSessionResponse = {
  session: Types.trainingSession,
  summary: Types.sessionSummary,
}

let endTrainingSession = (
  sessionId: string,
  toMsg: result<endSessionResponse, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/training/session/" ++ sessionId ++ "/end",
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
      callbacks.enqueue(toMsg(Ok({
        session: json["session"],
        summary: json["summary"],
      })))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to end session")))
      Js.Promise.resolve()
    }, _)
  })
}

let fetchCompetence = (toMsg: result<Types.competenceModel, string> => 'msg): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let _ = Fetch.fetchWithInit(
      apiUrl ++ "/training/competence",
      Fetch.RequestInit.make(
        ~headers=Fetch.HeadersInit.makeWithArray(makeHeaders()),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      callbacks.enqueue(toMsg(Ok(json["competence_model"])))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to fetch competence")))
      Js.Promise.resolve()
    }, _)
  })
}

// Quiz API

let fetchQuiz = (
  courseId: string,
  quizId: string,
  toMsg: result<Types.quiz, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let url = apiUrl ++ "/courses/" ++ courseId ++ "/quizzes/" ++ quizId
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
      callbacks.enqueue(toMsg(Error("Failed to fetch quiz")))
      Js.Promise.resolve()
    }, _)
  })
}

type startAttemptResponse = {
  attempt: Types.quizAttempt,
  questions: array<Types.question>,
}

let startQuizAttempt = (
  quizId: string,
  toMsg: result<startAttemptResponse, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let url = apiUrl ++ "/quizzes/" ++ quizId ++ "/attempts/new"
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
      callbacks.enqueue(toMsg(Ok({
        attempt: json["attempt"],
        questions: json["questions"],
      })))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to start quiz attempt")))
      Js.Promise.resolve()
    }, _)
  })
}

type submitAnswerResponse = {
  key: string,
  isCorrect: option<bool>,
  pointsEarned: int,
}

let submitQuizAnswer = (
  attemptId: string,
  questionKey: string,
  optionKey: option<string>,
  toMsg: result<submitAnswerResponse, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let url = apiUrl ++ "/attempts/" ++ attemptId ++ "/submit"
    let bodyObj = switch optionKey {
    | Some(key) => {"question_key": questionKey, "option_key": key}
    | None => {"question_key": questionKey, "option_key": ""}
    }
    let body = Js.Json.stringifyAny(bodyObj)->Belt.Option.getExn
    let _ = Fetch.fetchWithInit(
      url,
      Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Fetch.HeadersInit.makeWithArray(makeHeaders()),
        ~body=Fetch.BodyInit.make(body),
        (),
      ),
    )
    ->Js.Promise.then_(response => {
      Fetch.Response.json(response)
    }, _)
    ->Js.Promise.then_(json => {
      callbacks.enqueue(toMsg(Ok({
        key: json["key"],
        isCorrect: json["is_correct"],
        pointsEarned: json["points_earned"],
      })))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(_ => {
      callbacks.enqueue(toMsg(Error("Failed to submit answer")))
      Js.Promise.resolve()
    }, _)
  })
}

let completeQuizAttempt = (
  attemptId: string,
  toMsg: result<Types.quizAttempt, string> => 'msg,
): Cmd.t<'msg> => {
  Cmd.call(callbacks => {
    let url = apiUrl ++ "/attempts/" ++ attemptId ++ "/complete"
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
      callbacks.enqueue(toMsg(Error("Failed to complete quiz")))
      Js.Promise.resolve()
    }, _)
  })
}
