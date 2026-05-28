// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 Hyperpolymath

import AffineTEA;
import AffineTEARouter;

// Effects for IO and API calls
effect API {
  fn fetchCourses() -> Result<Vector<Course>, String>;
  fn fetchCompetence() -> Result<CompetenceModel, String>;
}

// Types
type User = {
  key: String,
  email: String,
  role: String,
}

type AuthState =
  | Anonymous
  | Loading
  | Authenticated(User)

type Route =
  | Home
  | Courses
  | Training
  | Login
  | NotFound

type ViewMode =
  | Windscreen  // Top-down / Through the windscreen
  | Chase       // Floating behind the car

type Model = {
  route: Route,
  auth: AuthState,
  loading: Bool,
  error: Option<String>,
  viewMode: ViewMode,
}

type Msg =
  | UrlChanged(Route)
  | GotCourses(Result<Vector<Course>, String>)
  | GotCompetence(Result<CompetenceModel, String>)
  | SwitchViewMode(ViewMode)

// Update
fn update(msg: Msg, model: Model) -> (Model, Cmd<Msg>) / API {
  match msg {
    UrlChanged(route) => {
      let new_model = { ...model, route: route, loading: true };
      match route {
        Home => (new_model, API.fetchCourses()),
        Training => (new_model, API.fetchCompetence()),
        _ => (new_model, Cmd.None)
      }
    }
    GotCourses(Ok(courses)) => {
      ({ ...model, loading: false }, Cmd.None)
    }
    GotCourses(Err(err)) => {
      ({ ...model, error: Some(err), loading: false }, Cmd.None)
    }
    SwitchViewMode(mode) => {
      ({ ...model, viewMode: mode }, Cmd.None)
    }
    _ => (model, Cmd.None)
  }
}

// View
fn view(model: Model) -> Html<Msg> {
  Html.div([Attr.class("app")], [
    Html.header([Attr.class("app-header")], [
      Html.div([Attr.class("logo")], [Html.text("🍬 Candy Crash LMS")]),
      Html.nav([Attr.class("main-nav")], [
        Html.button([Attr.class("nav-tab"), Ev.onClick(UrlChanged(Home))], [Html.text("Home")]),
        Html.button([Attr.class("nav-tab"), Ev.onClick(UrlChanged(Courses))], [Html.text("Courses")]),
        Html.button([Attr.class("nav-tab"), Ev.onClick(UrlChanged(Training))], [Html.text("Training")])
      ])
    ]),
    
    Html.div([Attr.class("camera-tabs")], [
      Html.button([
        Attr.class(if model.viewMode == Windscreen { "camera-tab active" } else { "camera-tab" }),
        Ev.onClick(SwitchViewMode(Windscreen))
      ], [Html.text("Windscreen")]),
      Html.button([
        Attr.class(if model.viewMode == Chase { "camera-tab active" } else { "camera-tab" }),
        Ev.onClick(SwitchViewMode(Chase))
      ], [Html.text("Chase Cam")])
    ]),

    Html.main([Attr.class("simulation-container")], [
      match model.viewMode {
        Windscreen => renderWindscreenView(model)
        Chase => renderChaseView(model)
      }
    ])
  ])
}

fn renderWindscreenView(model: Model) -> Html<Msg> {
  Html.div([Attr.class("view-windscreen")], [
    Html.text("Perspectives: Top-down / Windscreen active")
    // In a real implementation, this would trigger the WASM renderer's camera change
  ])
}

fn renderChaseView(model: Model) -> Html<Msg> {
  Html.div([Attr.class("view-chase")], [
    Html.text("Perspectives: Floating behind the car")
  ])
}

// Main
fn main() -> () {
  AffineTEA.program({
    init: fn() => ({ 
      route: Home, 
      auth: Anonymous, 
      loading: false, 
      error: None,
      viewMode: Chase
    }, Cmd.None),
    update: update,
    view: view,
    subscriptions: fn(_) => Sub.None
  });
}
