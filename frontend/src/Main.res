// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea
open Tea.Cmd
open Tea.Sub

// Types
type user = {
  key: string,
  email: string,
  role: string,
}

type authState =
  | Anonymous
  | Loading
  | Authenticated(user)

type route =
  | Home
  | About
  | Courses
  | CourseDetail(string)
  | Lesson(string, string)
  | Quiz(string, string)
  | Dashboard
  | Training
  | Demo
  | Login
  | Register
  | ForgotPassword
  | Privacy
  | Terms
  | NotFound

type model = {
  route: route,
  auth: authState,
  courses: array<Types.course>,
  currentCourse: option<Types.courseDetail>,
  currentLesson: option<Types.lesson>,
  enrollments: array<Types.enrollment>,
  loading: bool,
  error: option<string>,
  // Training state
  trainingState: Pages.Training.trainingState,
  interventionStartTime: option<float>,
  // Demo state
  demoState: Pages.Demo.demoState,
  demoStartTime: option<float>,
  demoElapsedMs: int,
  // Forgot password state
  forgotPasswordEmail: string,
  forgotPasswordState: Pages.ForgotPassword.forgotPasswordState,
}

type msg =
  | UrlChanged(route)
  | NavigateTo(route)
  | GotCourses(result<array<Types.course>, string>)
  | GotCourseDetail(result<Types.courseDetail, string>)
  | GotLesson(result<Types.lesson, string>)
  | LoginSubmit(string, string)
  | RegisterSubmit(string, string, string)
  | LoginResult(result<user, string>)
  | LogoutClicked
  | EnrollClicked(string)
  | EnrollResult(result<Types.enrollment, string>)
  | CompleteLessonClicked(string, string)
  | CompleteLessonResult(result<Types.lessonProgress, string>)
  | DismissError
  // Training messages
  | StartTrainingSession
  | TrainingSessionStarted(result<Api.startSessionResponse, string>)
  | RequestIntervention
  | GotIntervention(result<Api.nextInterventionResponse, string>)
  | RespondToIntervention(int)
  | GotInterventionResponse(result<Types.interventionResponse, string>)
  | EndTrainingSession
  | TrainingSessionEnded(result<Api.endSessionResponse, string>)
  | GotCompetence(result<Types.competenceModel, string>)
  // Demo messages
  | DemoStart
  | DemoCountdownTick
  | DemoStartChallenge
  | DemoTimerTick
  | DemoRespond
  | DemoNextChallenge
  | DemoEnd
  // Forgot password messages
  | ForgotPasswordEmailChanged(string)
  | ForgotPasswordSubmit
  | ForgotPasswordResult(result<string, string>)

// Route parsing
let parseRoute = (path: string): route => {
  let segments = path->Js.String2.split("/")->Belt.Array.keep(s => s != "")
  switch segments {
  | [] => Home
  | ["about"] => About
  | ["courses"] => Courses
  | ["courses", id] => CourseDetail(id)
  | ["courses", courseId, "lessons", lessonId] => Lesson(courseId, lessonId)
  | ["courses", courseId, "quizzes", quizId] => Quiz(courseId, quizId)
  | ["dashboard"] => Dashboard
  | ["training"] => Training
  | ["demo"] => Demo
  | ["login"] => Login
  | ["register"] => Register
  | ["forgot-password"] => ForgotPassword
  | ["privacy"] => Privacy
  | ["terms"] => Terms
  | _ => NotFound
  }
}

let routeToPath = (route: route): string => {
  switch route {
  | Home => "/"
  | About => "/about"
  | Courses => "/courses"
  | CourseDetail(id) => "/courses/" ++ id
  | Lesson(courseId, lessonId) => "/courses/" ++ courseId ++ "/lessons/" ++ lessonId
  | Quiz(courseId, quizId) => "/courses/" ++ courseId ++ "/quizzes/" ++ quizId
  | Dashboard => "/dashboard"
  | Training => "/training"
  | Demo => "/demo"
  | Login => "/login"
  | Register => "/register"
  | ForgotPassword => "/forgot-password"
  | Privacy => "/privacy"
  | Terms => "/terms"
  | NotFound => "/404"
  }
}

// Time helper
@val external performanceNow: unit => float = "performance.now"

// Initial training state
let initialTrainingState: Pages.Training.trainingState = {
  session: None,
  competence: None,
  phase: Pages.Training.Idle,
  interventionCount: 0,
}

// Init
let init = () => {
  let initialRoute = parseRoute(Router.getPath())
  let model = {
    route: initialRoute,
    auth: Anonymous,
    courses: [],
    currentCourse: None,
    currentLesson: None,
    enrollments: [],
    loading: false,
    error: None,
    trainingState: initialTrainingState,
    interventionStartTime: None,
    demoState: Pages.Demo.initialDemoState,
    demoStartTime: None,
    demoElapsedMs: 0,
    forgotPasswordEmail: "",
    forgotPasswordState: Pages.ForgotPassword.Ready,
  }

  let cmd = switch initialRoute {
  | Home | Courses => Api.fetchCourses(result => GotCourses(result))
  | CourseDetail(id) => Api.fetchCourse(id, result => GotCourseDetail(result))
  | Training => Api.fetchCompetence(result => GotCompetence(result))
  | _ => Cmd.none
  }

  (model, cmd)
}

// Update
let update = (model: model, msg: msg): (model, Cmd.t<msg>) => {
  switch msg {
  | UrlChanged(route) =>
    let cmd = switch route {
    | Home | Courses => Api.fetchCourses(result => GotCourses(result))
    | CourseDetail(id) => Api.fetchCourse(id, result => GotCourseDetail(result))
    | Lesson(courseId, lessonId) => Api.fetchLesson(courseId, lessonId, result => GotLesson(result))
    | Training => Api.fetchCompetence(result => GotCompetence(result))
    | _ => Cmd.none
    }
    ({...model, route, loading: true}, cmd)

  | NavigateTo(route) =>
    let _ = Router.pushPath(routeToPath(route))
    (model, Cmd.none)

  | GotCourses(Ok(courses)) =>
    ({...model, courses, loading: false}, Cmd.none)

  | GotCourses(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  | GotCourseDetail(Ok(course)) =>
    ({...model, currentCourse: Some(course), loading: false}, Cmd.none)

  | GotCourseDetail(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  | GotLesson(Ok(lesson)) =>
    ({...model, currentLesson: Some(lesson), loading: false}, Cmd.none)

  | GotLesson(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  | LoginSubmit(email, password) =>
    let cmd = Api.login(email, password, result => LoginResult(result))
    ({...model, loading: true}, cmd)

  | RegisterSubmit(email, password, _role) =>
    let cmd = Api.register(email, password, result => LoginResult(result))
    ({...model, loading: true}, cmd)

  | LoginResult(Ok(user)) =>
    ({...model, auth: Authenticated(user), loading: false, route: Dashboard}, Cmd.none)

  | LoginResult(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  | LogoutClicked =>
    let _ = Api.clearToken()
    ({...model, auth: Anonymous, route: Home}, Cmd.none)

  | EnrollClicked(courseId) =>
    let cmd = Api.enroll(courseId, result => EnrollResult(result))
    ({...model, loading: true}, cmd)

  | EnrollResult(Ok(enrollment)) =>
    let enrollments = Belt.Array.concat(model.enrollments, [enrollment])
    ({...model, enrollments, loading: false}, Cmd.none)

  | EnrollResult(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  | CompleteLessonClicked(courseId, lessonId) =>
    let cmd = Api.completeLesson(courseId, lessonId, result => CompleteLessonResult(result))
    ({...model, loading: true}, cmd)

  | CompleteLessonResult(Ok(_progress)) =>
    ({...model, loading: false}, Cmd.none)

  | CompleteLessonResult(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  | DismissError =>
    ({...model, error: None}, Cmd.none)

  // Training handlers
  | StartTrainingSession =>
    let cmd = Api.startTrainingSession("sitting", "car", result => TrainingSessionStarted(result))
    let trainingState = {...model.trainingState, phase: Pages.Training.AwaitingIntervention}
    ({...model, trainingState, loading: true}, cmd)

  | TrainingSessionStarted(Ok(response)) =>
    let trainingState = {
      ...model.trainingState,
      session: Some(response.session),
      phase: Pages.Training.Idle,
      interventionCount: 0,
    }
    let cmd = Api.fetchCompetence(result => GotCompetence(result))
    ({...model, trainingState, loading: false}, cmd)

  | TrainingSessionStarted(Error(err)) =>
    let trainingState = {...model.trainingState, phase: Pages.Training.Idle}
    ({...model, trainingState, error: Some(err), loading: false}, Cmd.none)

  | RequestIntervention =>
    switch model.trainingState.session {
    | Some(session) =>
      let sessionKey = Belt.Option.getWithDefault(session.key, "")
      let cmd = Api.getNextIntervention(sessionKey, result => GotIntervention(result))
      let trainingState = {...model.trainingState, phase: Pages.Training.AwaitingIntervention}
      ({...model, trainingState, loading: true}, cmd)
    | None => (model, Cmd.none)
    }

  | GotIntervention(Ok(response)) =>
    switch response {
    | Api.Intervention(intervention) =>
      let startTime = performanceNow()
      let trainingState = {
        ...model.trainingState,
        phase: Pages.Training.ShowingIntervention(intervention, startTime),
      }
      ({...model, trainingState, interventionStartTime: Some(startTime), loading: false}, Cmd.none)
    | Api.Wait(_ms, message) =>
      let trainingState = {...model.trainingState, phase: Pages.Training.ShowingFeedback("info", message)}
      ({...model, trainingState, loading: false}, Cmd.none)
    | Api.SessionComplete(message) =>
      let summary: Types.sessionSummary = {
        totalInterventions: model.trainingState.interventionCount,
        correctResponses: 0,
        accuracy: 0.0,
      }
      let trainingState = {...model.trainingState, phase: Pages.Training.SessionComplete(summary)}
      ({...model, trainingState, loading: false, error: Some(message)}, Cmd.none)
    }

  | GotIntervention(Error(err)) =>
    let trainingState = {...model.trainingState, phase: Pages.Training.Idle}
    ({...model, trainingState, error: Some(err), loading: false}, Cmd.none)

  | RespondToIntervention(_) =>
    switch (model.trainingState.session, model.interventionStartTime, model.trainingState.phase) {
    | (Some(session), Some(startTime), Pages.Training.ShowingIntervention(intervention, _)) =>
      let responseTime = Js.Math.floor_int(performanceNow() -. startTime)
      let sessionKey = Belt.Option.getWithDefault(session.key, "")
      let cmd = Api.respondToIntervention(
        intervention.id,
        sessionKey,
        responseTime,
        result => GotInterventionResponse(result),
      )
      ({...model, loading: true}, cmd)
    | _ => (model, Cmd.none)
    }

  | GotInterventionResponse(Ok(response)) =>
    let trainingState = {
      ...model.trainingState,
      phase: Pages.Training.ShowingFeedback(response.outcome, response.feedback),
      interventionCount: model.trainingState.interventionCount + 1,
    }
    let cmd = Api.fetchCompetence(result => GotCompetence(result))
    ({...model, trainingState, interventionStartTime: None, loading: false}, cmd)

  | GotInterventionResponse(Error(err)) =>
    let trainingState = {...model.trainingState, phase: Pages.Training.Idle}
    ({...model, trainingState, error: Some(err), loading: false}, Cmd.none)

  | EndTrainingSession =>
    switch model.trainingState.session {
    | Some(session) =>
      let sessionKey = Belt.Option.getWithDefault(session.key, "")
      let cmd = Api.endTrainingSession(sessionKey, result => TrainingSessionEnded(result))
      ({...model, loading: true}, cmd)
    | None => (model, Cmd.none)
    }

  | TrainingSessionEnded(Ok(response)) =>
    let trainingState = {
      ...model.trainingState,
      session: None,
      phase: Pages.Training.SessionComplete(response.summary),
    }
    ({...model, trainingState, loading: false}, Cmd.none)

  | TrainingSessionEnded(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  | GotCompetence(Ok(competence)) =>
    let trainingState = {...model.trainingState, competence: Some(competence)}
    ({...model, trainingState, loading: false}, Cmd.none)

  | GotCompetence(Error(err)) =>
    ({...model, error: Some(err), loading: false}, Cmd.none)

  // Demo handlers
  | DemoStart =>
    let demoState = {...Pages.Demo.initialDemoState, phase: Pages.Demo.DemoCountdown(3)}
    ({...model, demoState, demoElapsedMs: 0}, Cmd.none)

  | DemoCountdownTick =>
    switch model.demoState.phase {
    | Pages.Demo.DemoCountdown(count) =>
      if count <= 1 {
        // Start the challenge
        let (gapStart, gapEnd) = Pages.Demo.calculateGapWindow(model.demoState.currentDifficulty)
        let demoState = {
          ...model.demoState,
          phase: Pages.Demo.DemoChallenge(model.demoState.currentDifficulty, gapStart, gapEnd),
        }
        ({...model, demoState}, Cmd.none)
      } else {
        let demoState = {...model.demoState, phase: Pages.Demo.DemoCountdown(count - 1)}
        ({...model, demoState}, Cmd.none)
      }
    | _ => (model, Cmd.none)
    }

  | DemoStartChallenge =>
    switch model.demoState.phase {
    | Pages.Demo.DemoChallenge(difficulty, gapStart, gapEnd) =>
      let startTime = performanceNow()
      let demoState = {
        ...model.demoState,
        phase: Pages.Demo.DemoAwaitingResponse(startTime, difficulty, gapStart, gapEnd),
      }
      ({...model, demoState, demoStartTime: Some(startTime), demoElapsedMs: 0}, Cmd.none)
    | _ => (model, Cmd.none)
    }

  | DemoTimerTick =>
    switch (model.demoState.phase, model.demoStartTime) {
    | (Pages.Demo.DemoAwaitingResponse(_, difficulty, gapStart, gapEnd), Some(startTime)) =>
      let elapsed = Js.Math.floor_int(performanceNow() -. startTime)
      let totalDuration = gapEnd + 1000
      if elapsed >= totalDuration {
        // Timeout - user didn't respond
        let (outcome, message) = ("incorrect", "Timeout! You didn't respond in time.")
        let newState = Pages.Demo.updateCompetence(model.demoState, false)
        let demoState = {
          ...newState,
          phase: Pages.Demo.DemoFeedback(outcome, message, newState.competence),
        }
        ({...model, demoState, demoStartTime: None, demoElapsedMs: 0}, Cmd.none)
      } else {
        ({...model, demoElapsedMs: elapsed}, Cmd.none)
      }
    | _ => (model, Cmd.none)
    }

  | DemoRespond =>
    switch (model.demoState.phase, model.demoStartTime) {
    | (Pages.Demo.DemoAwaitingResponse(_, _difficulty, gapStart, gapEnd), Some(startTime)) =>
      let responseTime = Js.Math.floor_int(performanceNow() -. startTime)
      let (outcome, message) = Pages.Demo.evaluateResponse(responseTime, gapStart, gapEnd)
      let isCorrect = outcome == "correct"
      let newState = Pages.Demo.updateCompetence(model.demoState, isCorrect)
      let demoState = {
        ...newState,
        phase: Pages.Demo.DemoFeedback(outcome, message, newState.competence),
      }
      ({...model, demoState, demoStartTime: None, demoElapsedMs: 0}, Cmd.none)
    | _ => (model, Cmd.none)
    }

  | DemoNextChallenge =>
    let (gapStart, gapEnd) = Pages.Demo.calculateGapWindow(model.demoState.currentDifficulty)
    let demoState = {
      ...model.demoState,
      phase: Pages.Demo.DemoChallenge(model.demoState.currentDifficulty, gapStart, gapEnd),
    }
    ({...model, demoState, demoElapsedMs: 0}, Cmd.none)

  | DemoEnd =>
    let demoState = {...model.demoState, phase: Pages.Demo.DemoSummary}
    ({...model, demoState, demoStartTime: None, demoElapsedMs: 0}, Cmd.none)

  // Forgot password handlers
  | ForgotPasswordEmailChanged(email) =>
    ({...model, forgotPasswordEmail: email}, Cmd.none)

  | ForgotPasswordSubmit =>
    let cmd = Api.forgotPassword(model.forgotPasswordEmail, result => ForgotPasswordResult(result))
    ({...model, forgotPasswordState: Pages.ForgotPassword.Submitting}, cmd)

  | ForgotPasswordResult(Ok(_)) =>
    ({...model, forgotPasswordState: Pages.ForgotPassword.Sent}, Cmd.none)

  | ForgotPasswordResult(Error(err)) =>
    ({...model, forgotPasswordState: Pages.ForgotPassword.Error(err)}, Cmd.none)
  }
}

// Interval subscription helper
let every = (ms: int, toMsg: unit => 'msg): Sub.t<'msg> => {
  Sub.registration(
    "interval-" ++ Belt.Int.toString(ms),
    callbacks => {
      let intervalId = Js.Global.setInterval(() => {
        callbacks.enqueue(toMsg())
      }, ms)
      () => Js.Global.clearInterval(intervalId)
    },
  )
}

// Subscriptions
let subscriptions = (model: model): Sub.t<msg> => {
  let urlSub = Router.onUrlChange(path => UrlChanged(parseRoute(path)))

  // Demo timer subscriptions
  let demoSub = switch model.demoState.phase {
  | Pages.Demo.DemoCountdown(_) => every(1000, () => DemoCountdownTick)
  | Pages.Demo.DemoAwaitingResponse(_, _, _, _) => every(50, () => DemoTimerTick)
  | _ => Sub.none
  }

  Sub.batch([urlSub, demoSub])
}

// View
let view = (model: model): Html.t<msg> => {
  open Html

  div([class'("app")], [
    Components.Header.view(model.auth, msg => msg),
    main([class'("main-content")], [
      switch model.error {
      | Some(err) => Components.ErrorBanner.view(err, DismissError)
      | None => noNode
      },
      switch model.loading {
      | true => Components.Loading.view()
      | false =>
        switch model.route {
        | Home => Pages.Home.view(model.courses, msg => msg)
        | About => Pages.About.view()
        | Courses => Pages.Courses.view(model.courses, msg => msg)
        | CourseDetail(id) =>
          switch model.currentCourse {
          | Some(course) => Pages.CourseDetail.view(course, model.auth, msg => msg)
          | None => Components.Loading.view()
          }
        | Lesson(courseId, lessonId) =>
          switch model.currentLesson {
          | Some(lesson) => Pages.Lesson.view(lesson, courseId, msg => msg)
          | None => Components.Loading.view()
          }
        | Quiz(courseId, quizId) => Pages.Quiz.view(courseId, quizId, msg => msg)
        | Dashboard =>
          switch model.auth {
          | Authenticated(user) => Pages.Dashboard.view(user, model.enrollments)
          | _ => Pages.Login.view(msg => msg)
          }
        | Training =>
          switch model.auth {
          | Authenticated(_) =>
            Pages.Training.view(
              model.trainingState,
              () => StartTrainingSession,
              () => RequestIntervention,
              responseTime => RespondToIntervention(responseTime),
              () => EndTrainingSession,
            )
          | _ => Pages.Login.view(msg => msg)
          }
        | Demo =>
          Pages.Demo.view(
            model.demoState,
            () => DemoStart,
            () => DemoStartChallenge,
            () => DemoRespond,
            () => DemoNextChallenge,
            () => DemoEnd,
            model.demoElapsedMs,
          )
        | Login => Pages.Login.view(msg => msg)
        | Register => Pages.Register.view(msg => msg)
        | ForgotPassword =>
          Pages.ForgotPassword.view(
            model.forgotPasswordEmail,
            model.forgotPasswordState,
            email => ForgotPasswordEmailChanged(email),
            () => ForgotPasswordSubmit,
          )
        | Privacy => Pages.Privacy.view()
        | Terms => Pages.Terms.view()
        | NotFound => Pages.NotFound.view()
        }
      },
    ]),
    Components.Footer.view(),
  ])
}

// Program
let main = Tea.App.program({
  init,
  update,
  view,
  subscriptions,
})
