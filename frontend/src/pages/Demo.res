// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

open Tea.Html

// Demo state types
type demoPhase =
  | DemoIntro
  | DemoCountdown(int)
  | DemoChallenge(float, int, int)  // difficulty, gapStart, gapEnd
  | DemoAwaitingResponse(float, float, int, int)  // startTime, difficulty, gapStart, gapEnd
  | DemoFeedback(string, string, float)  // outcome, message, newCompetence
  | DemoSummary

type demoState = {
  phase: demoPhase,
  competence: float,
  confidence: float,
  totalAttempts: int,
  correctAttempts: int,
  currentDifficulty: float,
}

// Initial demo state
let initialDemoState: demoState = {
  phase: DemoIntro,
  competence: 0.0,
  confidence: 0.0,
  totalAttempts: 0,
  correctAttempts: 0,
  currentDifficulty: 0.3,
}

// Calculate gap window based on difficulty
let calculateGapWindow = (difficulty: float): (int, int) => {
  // Base approach time: 2000ms
  // Gap duration: 3000ms at 0 difficulty, 1000ms at 1.0 difficulty
  let gapDuration = Js.Math.floor_int(3000.0 -. difficulty *. 2000.0)
  let gapStart = 2000
  let gapEnd = gapStart + gapDuration
  (gapStart, gapEnd)
}

// Evaluate response timing
let evaluateResponse = (responseTime: int, gapStart: int, gapEnd: int): (string, string) => {
  if responseTime < gapStart {
    ("incorrect", "Too early! You responded at " ++ Belt.Int.toString(responseTime) ++ "ms, but the gap started at " ++ Belt.Int.toString(gapStart) ++ "ms.")
  } else if responseTime > gapEnd {
    ("incorrect", "Too late! You responded at " ++ Belt.Int.toString(responseTime) ++ "ms, but the gap ended at " ++ Belt.Int.toString(gapEnd) ++ "ms.")
  } else {
    ("correct", "Excellent! You identified the gap correctly at " ++ Belt.Int.toString(responseTime) ++ "ms (gap window: " ++ Belt.Int.toString(gapStart) ++ "-" ++ Belt.Int.toString(gapEnd) ++ "ms).")
  }
}

// Update competence based on outcome
let updateCompetence = (state: demoState, isCorrect: bool): demoState => {
  let newTotal = state.totalAttempts + 1
  let newCorrect = if isCorrect { state.correctAttempts + 1 } else { state.correctAttempts }
  let successRate = Belt.Int.toFloat(newCorrect) /. Belt.Int.toFloat(newTotal)

  // Competence moves toward success rate
  let newCompetence = state.competence *. 0.8 +. successRate *. 0.2

  // Confidence increases with attempts
  let newConfidence = Js.Math.min_float(1.0, state.confidence +. 0.1)

  // Adjust difficulty based on success rate
  let newDifficulty = if successRate > 0.85 {
    Js.Math.min_float(1.0, state.currentDifficulty +. 0.1)
  } else if successRate < 0.55 {
    Js.Math.max_float(0.1, state.currentDifficulty -. 0.1)
  } else {
    state.currentDifficulty
  }

  {
    ...state,
    competence: newCompetence,
    confidence: newConfidence,
    totalAttempts: newTotal,
    correctAttempts: newCorrect,
    currentDifficulty: newDifficulty,
  }
}

// Progress bar component
let progressBar = (value: float, label: string, colorClass: string): t<'msg> => {
  let percentage = Js.Float.toFixedWithPrecision(value *. 100.0, ~digits=0) ++ "%"
  div([class'("demo-progress-container")], [
    div([class'("demo-progress-label")], [text(label)]),
    div([class'("demo-progress-bar")], [
      div([
        class'("demo-progress-fill " ++ colorClass),
        Vdom.style("width", percentage),
      ], []),
    ]),
    div([class'("demo-progress-value")], [text(percentage)]),
  ])
}

// Timer visualization
let timerVisualization = (elapsedMs: int, gapStart: int, gapEnd: int, totalDuration: int): t<'msg> => {
  let progress = Belt.Int.toFloat(elapsedMs) /. Belt.Int.toFloat(totalDuration) *. 100.0
  let gapStartPct = Belt.Int.toFloat(gapStart) /. Belt.Int.toFloat(totalDuration) *. 100.0
  let gapEndPct = Belt.Int.toFloat(gapEnd) /. Belt.Int.toFloat(totalDuration) *. 100.0

  div([class'("timer-visualization")], [
    div([class'("timer-track")], [
      // Gap window indicator
      div([
        class'("timer-gap-window"),
        Vdom.style("left", Js.Float.toString(gapStartPct) ++ "%"),
        Vdom.style("width", Js.Float.toString(gapEndPct -. gapStartPct) ++ "%"),
      ], []),
      // Progress indicator
      div([
        class'("timer-progress"),
        Vdom.style("width", Js.Float.toString(progress) ++ "%"),
      ], []),
    ]),
    div([class'("timer-labels")], [
      span([], [text("0s")]),
      span([class'("gap-label")], [text("Gap Window")]),
      span([], [text(Js.Float.toFixedWithPrecision(Belt.Int.toFloat(totalDuration) /. 1000.0, ~digits=1) ++ "s")]),
    ]),
  ])
}

// Main demo view
let view = (
  state: demoState,
  onStartDemo: unit => 'msg,
  onStartChallenge: unit => 'msg,
  onRespond: unit => 'msg,
  onNextChallenge: unit => 'msg,
  onEndDemo: unit => 'msg,
  elapsedMs: int,
): t<'msg> => {
  div([class'("demo-page")], [
    div([class'("container")], [
      // Header
      div([class'("demo-header")], [
        h1([], [text("Training Loop Demo")]),
        p([class'("demo-subtitle")], [
          text("Experience the Gap Timing Perception trainer - no login required!"),
        ]),
      ]),

      // Stats panel (always visible after starting)
      switch state.phase {
      | DemoIntro => noNode
      | _ =>
        div([class'("demo-stats-panel")], [
          h3([], [text("Your Progress")]),
          div([class'("demo-stats-grid")], [
            progressBar(state.competence, "Competence", "competence"),
            progressBar(state.confidence, "Confidence", "confidence"),
            div([class'("demo-stat-box")], [
              div([class'("demo-stat-value")], [
                text(Belt.Int.toString(state.totalAttempts)),
              ]),
              div([class'("demo-stat-label")], [text("Attempts")]),
            ]),
            div([class'("demo-stat-box")], [
              div([class'("demo-stat-value")], [
                text(
                  if state.totalAttempts > 0 {
                    Js.Float.toFixedWithPrecision(
                      Belt.Int.toFloat(state.correctAttempts) /. Belt.Int.toFloat(state.totalAttempts) *. 100.0,
                      ~digits=0
                    ) ++ "%"
                  } else {
                    "0%"
                  }
                ),
              ]),
              div([class'("demo-stat-label")], [text("Accuracy")]),
            ]),
            div([class'("demo-stat-box")], [
              div([class'("demo-stat-value")], [
                text(Js.Float.toFixedWithPrecision(state.currentDifficulty *. 100.0, ~digits=0) ++ "%"),
              ]),
              div([class'("demo-stat-label")], [text("Difficulty")]),
            ]),
          ]),
        ])
      },

      // Main interaction area
      div([class'("demo-main")], [
        switch state.phase {
        | DemoIntro =>
          div([class'("demo-intro")], [
            div([class'("demo-icon")], [text("🚗")]),
            h2([], [text("Gap Timing Perception")]),
            p([class'("demo-description")], [
              text("This demo trains your ability to perceive safe gaps in traffic. "),
              text("When you see 'Vehicle Approaching', wait for the right moment and press "),
              strong([], [text("GAP!")]),
              text(" when you perceive it's safe to cross."),
            ]),
            div([class'("demo-how-it-works")], [
              h3([], [text("How It Works")]),
              ol([], [
                li([], [text("A 'vehicle' approaches (simulated by a timer)")]),
                li([], [text("Watch for the green 'Gap Window' zone")]),
                li([], [text("Press GAP! while the timer is in the green zone")]),
                li([], [text("Difficulty adapts to your performance")]),
              ]),
            ]),
            button([
              class'("btn btn-primary btn-large demo-start-btn"),
              onClick(onStartDemo()),
            ], [text("Start Demo")]),
          ])

        | DemoCountdown(count) =>
          div([class'("demo-countdown")], [
            div([class'("countdown-number")], [text(Belt.Int.toString(count))]),
            p([], [text("Get ready...")]),
          ])

        | DemoChallenge(difficulty, gapStart, gapEnd) =>
          let totalDuration = gapEnd + 1000
          div([class'("demo-challenge")], [
            h2([], [text("Challenge Starting...")]),
            div([class'("difficulty-badge")], [
              text("Difficulty: " ++ Js.Float.toFixedWithPrecision(difficulty *. 100.0, ~digits=0) ++ "%"),
            ]),
            p([], [text("Press GAP! when you see the timer enter the green zone")]),
            timerVisualization(0, gapStart, gapEnd, totalDuration),
            button([
              class'("btn btn-primary"),
              onClick(onStartChallenge()),
            ], [text("Begin")]),
          ])

        | DemoAwaitingResponse(_startTime, difficulty, gapStart, gapEnd) =>
          let totalDuration = gapEnd + 1000
          let inGapWindow = elapsedMs >= gapStart && elapsedMs <= gapEnd
          div([class'("demo-active-challenge")], [
            h2([class'(if inGapWindow { "pulse-green" } else { "" })], [
              text(if inGapWindow { "GAP WINDOW OPEN!" } else { "Vehicle Approaching..." }),
            ]),
            div([class'("difficulty-badge")], [
              text("Difficulty: " ++ Js.Float.toFixedWithPrecision(difficulty *. 100.0, ~digits=0) ++ "%"),
            ]),
            timerVisualization(elapsedMs, gapStart, gapEnd, totalDuration),
            div([class'("elapsed-time")], [
              text("Time: " ++ Belt.Int.toString(elapsedMs) ++ "ms"),
            ]),
            button([
              class'("btn btn-success btn-huge response-button " ++ if inGapWindow { "pulse" } else { "" }),
              onClick(onRespond()),
            ], [text("GAP!")]),
            p([class'("hint")], [
              text(if inGapWindow {
                "NOW! The gap is open!"
              } else if elapsedMs < gapStart {
                "Wait for the green zone..."
              } else {
                "Gap window passed!"
              }),
            ]),
          ])

        | DemoFeedback(outcome, message, newCompetence) =>
          div([class'("demo-feedback")], [
            div([class'("feedback-result " ++ outcome)], [
              div([class'("feedback-icon-large")], [
                text(switch outcome {
                | "correct" => "✓"
                | _ => "✗"
                }),
              ]),
              h2([], [text(switch outcome {
              | "correct" => "Correct!"
              | _ => "Incorrect"
              })]),
            ]),
            p([class'("feedback-message")], [text(message)]),
            div([class'("competence-update")], [
              text("Competence: " ++ Js.Float.toFixedWithPrecision(newCompetence *. 100.0, ~digits=1) ++ "%"),
            ]),
            div([class'("demo-feedback-actions")], [
              button([
                class'("btn btn-primary btn-large"),
                onClick(onNextChallenge()),
              ], [text("Next Challenge")]),
              button([
                class'("btn btn-secondary"),
                onClick(onEndDemo()),
              ], [text("End Demo")]),
            ]),
          ])

        | DemoSummary =>
          let accuracy = if state.totalAttempts > 0 {
            Belt.Int.toFloat(state.correctAttempts) /. Belt.Int.toFloat(state.totalAttempts) *. 100.0
          } else {
            0.0
          }
          div([class'("demo-summary")], [
            div([class'("summary-icon")], [text("🎯")]),
            h2([], [text("Demo Complete!")]),
            div([class'("summary-stats")], [
              div([class'("summary-stat")], [
                span([class'("stat-value-large")], [text(Belt.Int.toString(state.totalAttempts))]),
                span([class'("stat-label")], [text("Challenges")]),
              ]),
              div([class'("summary-stat")], [
                span([class'("stat-value-large")], [text(Belt.Int.toString(state.correctAttempts))]),
                span([class'("stat-label")], [text("Correct")]),
              ]),
              div([class'("summary-stat")], [
                span([class'("stat-value-large")], [
                  text(Js.Float.toFixedWithPrecision(accuracy, ~digits=0) ++ "%"),
                ]),
                span([class'("stat-label")], [text("Accuracy")]),
              ]),
              div([class'("summary-stat")], [
                span([class'("stat-value-large")], [
                  text(Js.Float.toFixedWithPrecision(state.competence *. 100.0, ~digits=0) ++ "%"),
                ]),
                span([class'("stat-label")], [text("Final Competence")]),
              ]),
            ]),
            div([class'("summary-message")], [
              p([], [
                text(
                  if accuracy >= 80.0 {
                    "Excellent perception skills! You're ready for more advanced training."
                  } else if accuracy >= 60.0 {
                    "Good progress! Keep practicing to improve your gap timing."
                  } else {
                    "Keep practicing! Gap timing improves with consistent training."
                  }
                ),
              ]),
            ]),
            div([class'("summary-actions")], [
              button([
                class'("btn btn-primary btn-large"),
                onClick(onStartDemo()),
              ], [text("Try Again")]),
            ]),
            div([class'("summary-cta")], [
              p([], [text("Want to track your progress over time?")]),
              a([href("/login"), class'("btn btn-secondary")], [text("Sign up for full access")]),
            ]),
          ])
        },
      ]),

      // Info section
      div([class'("demo-info")], [
        h3([], [text("About This Training")]),
        div([class'("info-grid")], [
          div([class'("info-card")], [
            div([class'("info-icon")], [text("🧠")]),
            h4([], [text("Perceptual Learning")]),
            p([], [text("Gap timing is a core driving skill. This trainer helps you develop accurate perception of safe crossing intervals.")]),
          ]),
          div([class'("info-card")], [
            div([class'("info-icon")], [text("📈")]),
            h4([], [text("Adaptive Difficulty")]),
            p([], [text("The system adjusts challenge difficulty based on your performance, keeping you in the optimal learning zone.")]),
          ]),
          div([class'("info-card")], [
            div([class'("info-icon")], [text("🎯")]),
            h4([], [text("Competence Tracking")]),
            p([], [text("Your competence score reflects your skill level, while confidence indicates how reliable that estimate is.")]),
          ]),
        ]),
      ]),
    ]),
  ])
}
