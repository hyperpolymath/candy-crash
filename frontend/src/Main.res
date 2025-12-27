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
  | Login
  | Register
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
  | ["login"] => Login
  | ["register"] => Register
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
  | Login => "/login"
  | Register => "/register"
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
  }
}

// Subscriptions
let subscriptions = (_model: model): Sub.t<msg> => {
  Router.onUrlChange(path => UrlChanged(parseRoute(path)))
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
        | Login => Pages.Login.view(msg => msg)
        | Register => Pages.Register.view(msg => msg)
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
