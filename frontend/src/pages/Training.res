// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

// Training page state
type trainingPhase =
  | Idle
  | AwaitingIntervention
  | ShowingIntervention(Types.intervention, float)  // intervention + start time
  | ShowingFeedback(string, string)  // outcome + feedback message
  | SessionComplete(Types.sessionSummary)

type trainingState = {
  session: option<Types.trainingSession>,
  competence: option<Types.competenceModel>,
  phase: trainingPhase,
  interventionCount: int,
}

// View helper for competence bar
let competenceBar = (level: float): t<'msg> => {
  let percentage = Js.Float.toString(level *. 100.0) ++ "%"
  div([class'("competence-bar")], [
    div([
      class'("competence-fill"),
      Vdom.style("width", percentage),
    ], []),
    span([class'("competence-label")], [text(percentage)]),
  ])
}

// View helper for skill card
let skillCard = (skill: Types.skillState): t<'msg> => {
  div([class'("skill-card")], [
    h4([], [text(skill.skillId)]),
    div([class'("skill-stats")], [
      div([], [
        span([class'("stat-label")], [text("Competence: ")]),
        competenceBar(skill.competence),
      ]),
      div([], [
        span([class'("stat-label")], [text("Confidence: ")]),
        text(Js.Float.toFixedWithPrecision(skill.confidence *. 100.0, ~digits=0) ++ "%"),
      ]),
      div([], [
        span([class'("stat-label")], [text("Attempts: ")]),
        text(Belt.Int.toString(skill.attemptCount)),
      ]),
      div([], [
        span([class'("stat-label")], [text("Success Rate: ")]),
        text(
          if skill.attemptCount > 0 {
            Js.Float.toFixedWithPrecision(
              Belt.Int.toFloat(skill.successCount) /. Belt.Int.toFloat(skill.attemptCount) *. 100.0,
              ~digits=0
            ) ++ "%"
          } else {
            "N/A"
          }
        ),
      ]),
    ]),
  ])
}

// Main training interface view
let view = (
  state: trainingState,
  onStartSession: unit => 'msg,
  onRequestIntervention: unit => 'msg,
  onRespond: int => 'msg,
  onEndSession: unit => 'msg,
): t<'msg> => {
  div([class'("training-page")], [
    div([class'("container")], [
      // Header
      div([class'("training-header")], [
        h1([], [text("Gap Timing Training")]),
        p([class'("training-description")], [
          text("Train your ability to perceive safe gaps in traffic flow. "),
          text("When you hear the approaching vehicle sound, press the button when you perceive a safe gap to cross."),
        ]),
      ]),

      // Competence display
      switch state.competence {
      | Some(model) =>
        div([class'("competence-section")], [
          h2([], [text("Your Competence")]),
          div([class'("skills-grid")],
            Belt.Array.map(model.skills, skillCard)->Belt.Array.toList
          ),
        ])
      | None =>
        div([class'("competence-section")], [
          p([], [text("Start a training session to see your competence model.")]),
        ])
      },

      // Training interface based on phase
      div([class'("training-interface")], [
        switch state.phase {
        | Idle =>
          switch state.session {
          | Some(_) =>
            // Session exists but idle
            div([class'("training-controls")], [
              button([
                class'("btn btn-primary btn-large"),
                onClick(onRequestIntervention()),
              ], [text("Get Next Challenge")]),
              button([
                class'("btn btn-secondary"),
                onClick(onEndSession()),
              ], [text("End Session")]),
            ])
          | None =>
            // No session - show start button
            div([class'("training-start")], [
              h2([], [text("Ready to Train?")]),
              p([], [text("Start a training session to practice gap timing perception.")]),
              button([
                class'("btn btn-primary btn-large"),
                onClick(onStartSession()),
              ], [text("Start Training Session")]),
            ])
          }

        | AwaitingIntervention =>
          div([class'("awaiting-intervention")], [
            div([class'("spinner")], []),
            p([], [text("Preparing next challenge...")]),
          ])

        | ShowingIntervention(intervention, _startTime) =>
          div([class'("intervention-active")], [
            h2([], [text("Listen for the Gap!")]),
            p([class'("intervention-instructions")], [
              text("A vehicle is approaching. Press the button when you perceive a safe gap."),
            ]),
            div([class'("difficulty-indicator")], [
              text("Difficulty: "),
              text(Js.Float.toFixedWithPrecision(intervention.difficulty *. 100.0, ~digits=0) ++ "%"),
            ]),
            // Gap timing visualization
            div([class'("gap-visualization")], [
              div([class'("traffic-indicator approaching")], [
                text("Vehicle Approaching..."),
              ]),
            ]),
            // Response button
            button([
              class'("btn btn-success btn-huge response-button"),
              onClick(onRespond(0)),  // Response time calculated in parent
            ], [text("GAP!")]),
            p([class'("hint")], [text("Press when you perceive a safe crossing gap")]),
          ])

        | ShowingFeedback(outcome, feedback) =>
          div([class'("feedback-display")], [
            div([class'(
              "feedback-icon " ++ switch outcome {
              | "correct" => "success"
              | "incorrect" => "error"
              | "timeout" => "warning"
              | _ => "info"
              }
            )], [
              text(switch outcome {
              | "correct" => "Correct!"
              | "incorrect" => "Incorrect"
              | "timeout" => "Timeout"
              | _ => outcome
              }),
            ]),
            p([class'("feedback-message")], [text(feedback)]),
            button([
              class'("btn btn-primary"),
              onClick(onRequestIntervention()),
            ], [text("Next Challenge")]),
            button([
              class'("btn btn-secondary"),
              onClick(onEndSession()),
            ], [text("End Session")]),
          ])

        | SessionComplete(summary) =>
          div([class'("session-complete")], [
            h2([], [text("Session Complete!")]),
            div([class'("session-summary")], [
              div([class'("summary-stat")], [
                span([class'("stat-value")], [text(Belt.Int.toString(summary.totalInterventions))]),
                span([class'("stat-label")], [text("Total Challenges")]),
              ]),
              div([class'("summary-stat")], [
                span([class'("stat-value")], [text(Belt.Int.toString(summary.correctResponses))]),
                span([class'("stat-label")], [text("Correct Responses")]),
              ]),
              div([class'("summary-stat")], [
                span([class'("stat-value")], [
                  text(Js.Float.toFixedWithPrecision(summary.accuracy *. 100.0, ~digits=0) ++ "%"),
                ]),
                span([class'("stat-label")], [text("Accuracy")]),
              ]),
            ]),
            button([
              class'("btn btn-primary btn-large"),
              onClick(onStartSession()),
            ], [text("Start New Session")]),
          ])
        },
      ]),

      // Session info
      switch state.session {
      | Some(session) =>
        div([class'("session-info")], [
          p([], [
            text("Session: "),
            text(Belt.Option.getWithDefault(session.key, "unknown")),
          ]),
          p([], [
            text("Interventions this session: "),
            text(Belt.Int.toString(state.interventionCount)),
          ]),
        ])
      | None => noNode
      },

      // Training tips
      div([class'("training-tips")], [
        h3([], [text("Training Tips")]),
        ul([], [
          li([], [text("Focus on the rhythm of the approaching sound")]),
          li([], [text("Imagine yourself as a pedestrian waiting to cross")]),
          li([], [text("The gap window varies - harder challenges have shorter gaps")]),
          li([], [text("Consistent practice improves your perception over time")]),
        ]),
      ]),
    ]),
  ])
}
