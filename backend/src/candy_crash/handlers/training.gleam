// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import birl
import gleam/dynamic
import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

import candy_crash/arango/client
import candy_crash/context.{type AuthContext, type Context}
import candy_crash/models/training.{
  type Activity, type CompetenceModel, type Intervention, type InterventionContent,
  type InterventionResult, type MicroSkill, type Outcome, type SkillState,
  type TraineeState, type TrainingSession, type VehicleDomain,
  Audio, Car, Correct, GapTiming, Incorrect, Perception, SessionActive,
  SessionCompleted, Sitting, Skipped, Timeout, Walking,
}

// ============================================================================
// Gap Timing Skill Definition (MVP)
// ============================================================================

fn gap_timing_skill() -> MicroSkill {
  training.MicroSkill(
    id: "gap_timing_perception",
    name: "Gap Timing Perception",
    description: "The ability to perceive and judge time gaps in traffic flow",
    domain: Car,
    sa_level: Perception,
    ambient_trainable: True,
    modalities: [Audio],
  )
}

fn get_default_skills() -> List(MicroSkill) {
  [gap_timing_skill()]
}

// ============================================================================
// Session Management
// ============================================================================

/// GET /api/training/skills - List available micro-skills
pub fn list_skills(_req: Request, _ctx: Context) -> Response {
  let skills = get_default_skills()

  json.object([
    #("skills", json.array(skills, training.micro_skill_to_json)),
  ])
  |> json.to_string_builder
  |> wisp.json_response(200)
}

/// POST /api/training/session/start - Start a new training session
pub fn start_session(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_json(req)

      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let now = birl.now() |> birl.to_iso8601

      // Parse request body for activity and domain
      let activity = dynamic.field("activity", dynamic.string)(body)
        |> result.unwrap("")
        |> training.activity_from_string

      let domain = dynamic.field("domain", dynamic.string)(body)
        |> result.unwrap("car")
        |> training.domain_from_string

      // Create new session
      let session = training.new_training_session(user_key, domain, now, activity)
      let session_json = json.object([
        #("user_key", json.string(session.user_key)),
        #("domain", json.string(training.domain_to_string(session.domain))),
        #("started_at", json.string(session.started_at)),
        #("status", json.string(training.session_status_to_string(session.status))),
        #("initial_activity", json.string(training.activity_to_string(session.initial_activity))),
        #("interventions", json.array([], fn(_) { json.null() })),
      ])

      case client.insert_document(
        auth_ctx.db,
        "training_sessions",
        session_json,
        training.training_session_decoder,
      ) {
        Ok(s) -> {
          // Also ensure competence model exists for this user/domain
          let _ = ensure_competence_model(auth_ctx, user_key, domain)

          let trainee_state = training.new_trainee_state(activity)

          json.object([
            #("session", training.training_session_to_json(s)),
            #("trainee_state", training.trainee_state_to_json(trainee_state)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(201)
        }
        Error(_) -> error_response("Failed to start training session", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

/// GET /api/training/session/:id - Get session state
pub fn get_session(req: Request, auth_ctx: AuthContext, session_id: String) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      let query = "
        FOR s IN training_sessions
        FILTER s._key == @session_id AND s.user_key == @user_key
        RETURN s
      "

      case client.query(auth_ctx.db, query, [
        #("session_id", json.string(session_id)),
        #("user_key", json.string(user_key)),
      ], training.training_session_decoder) {
        Ok(result) -> {
          case result.result {
            [session, ..] -> {
              // Get competence model
              let model_result = get_competence_model(auth_ctx, user_key, session.domain)

              // Calculate time until next intervention
              let budget = training.default_attention_budget()
              let interventions_count = list.length(session.interventions)
              let wait_ms = case interventions_count >= budget.max_interventions_per_hour {
                True -> -1  // Session exhausted
                False -> 0  // Ready now (simplified)
              }

              json.object([
                #("session", training.training_session_to_json(session)),
                #("competence_model", case model_result {
                  Ok(m) -> training.competence_model_to_json(m)
                  Error(_) -> json.null()
                }),
                #("next_intervention_available_in_ms", json.int(wait_ms)),
              ])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            [] -> error_response("Session not found", 404)
          }
        }
        Error(_) -> error_response("Failed to fetch session", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

/// POST /api/training/session/:id/next - Get next intervention
pub fn next_intervention(req: Request, auth_ctx: AuthContext, session_id: String) -> Response {
  case req.method {
    http.Post -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      // Fetch session
      let query = "
        FOR s IN training_sessions
        FILTER s._key == @session_id AND s.user_key == @user_key AND s.status == 'active'
        RETURN s
      "

      case client.query(auth_ctx.db, query, [
        #("session_id", json.string(session_id)),
        #("user_key", json.string(user_key)),
      ], training.training_session_decoder) {
        Ok(result) -> {
          case result.result {
            [session, ..] -> {
              // Check attention budget
              let budget = training.default_attention_budget()
              let intervention_count = list.length(session.interventions)

              case intervention_count >= budget.max_interventions_per_hour {
                True -> {
                  json.object([
                    #("session_complete", json.bool(True)),
                    #("message", json.string("Maximum interventions reached for this session")),
                  ])
                  |> json.to_string_builder
                  |> wisp.json_response(200)
                }
                False -> {
                  // Get competence model and select skill
                  case get_competence_model(auth_ctx, user_key, session.domain) {
                    Ok(model) -> {
                      // Select highest value skill
                      let skill_state = select_best_skill(model.skills)

                      case skill_state {
                        Some(skill) -> {
                          // Generate intervention
                          let intervention = generate_gap_timing_intervention(
                            skill,
                            intervention_count + 1,
                          )

                          json.object([
                            #("intervention", training.intervention_to_json(intervention)),
                          ])
                          |> json.to_string_builder
                          |> wisp.json_response(200)
                        }
                        None -> {
                          json.object([
                            #("wait_ms", json.int(60000)),  // Wait 1 minute
                            #("message", json.string("No skills need training right now")),
                          ])
                          |> json.to_string_builder
                          |> wisp.json_response(200)
                        }
                      }
                    }
                    Error(_) -> error_response("Failed to load competence model", 500)
                  }
                }
              }
            }
            [] -> error_response("Active session not found", 404)
          }
        }
        Error(_) -> error_response("Failed to fetch session", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

/// POST /api/training/intervention/:id/respond - Submit response to intervention
pub fn respond_to_intervention(req: Request, auth_ctx: AuthContext, intervention_id: String) -> Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_json(req)

      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let now = birl.now() |> birl.to_iso8601

      // Parse response
      let response_time_ms = dynamic.field("response_time_ms", dynamic.int)(body)
        |> result.unwrap(0)

      let session_id = dynamic.field("session_id", dynamic.string)(body)
        |> result.unwrap("")

      // Parse the intervention ID to get gap timing parameters
      // Format: gap_timing_N_difficulty_D_gap_START_END
      let parts = string.split(intervention_id, "_")

      // Extract gap window from intervention ID (simplified parsing)
      let gap_start_ms = list.at(parts, 5) |> result.unwrap("2000") |> int.parse |> result.unwrap(2000)
      let gap_end_ms = list.at(parts, 6) |> result.unwrap("4000") |> int.parse |> result.unwrap(4000)

      // Evaluate response
      let outcome = evaluate_gap_timing_response(response_time_ms, gap_start_ms, gap_end_ms)

      // Create intervention result
      let result_record = training.InterventionResult(
        intervention_id: intervention_id,
        delivered_at: now,
        response_time_ms: Some(response_time_ms),
        outcome: outcome,
      )

      // Update session with new intervention result
      let update_query = "
        FOR s IN training_sessions
        FILTER s._key == @session_id AND s.user_key == @user_key
        UPDATE s WITH {
          interventions: APPEND(s.interventions, [@result])
        } IN training_sessions
        RETURN NEW
      "

      let result_json = training.intervention_result_to_json(result_record)

      case client.query(auth_ctx.db, update_query, [
        #("session_id", json.string(session_id)),
        #("user_key", json.string(user_key)),
        #("result", result_json),
      ], training.training_session_decoder) {
        Ok(_) -> {
          // Update competence model
          let _ = update_competence_after_intervention(
            auth_ctx,
            user_key,
            Car,
            "gap_timing_perception",
            outcome,
            now,
          )

          // Get updated competence
          let new_competence = case get_competence_model(auth_ctx, user_key, Car) {
            Ok(model) -> {
              list.find(model.skills, fn(s) { s.skill_id == "gap_timing_perception" })
              |> result.map(fn(s) { s.competence })
              |> result.unwrap(0.0)
            }
            Error(_) -> 0.0
          }

          json.object([
            #("outcome", json.string(training.outcome_to_string(outcome))),
            #("new_competence", json.float(new_competence)),
            #("feedback", json.string(get_feedback_message(outcome, response_time_ms, gap_start_ms, gap_end_ms))),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> error_response("Failed to record response", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

/// POST /api/training/session/:id/end - End training session
pub fn end_session(req: Request, auth_ctx: AuthContext, session_id: String) -> Response {
  case req.method {
    http.Post -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")
      let now = birl.now() |> birl.to_iso8601

      let query = "
        FOR s IN training_sessions
        FILTER s._key == @session_id AND s.user_key == @user_key
        UPDATE s WITH {
          ended_at: @now,
          status: 'completed'
        } IN training_sessions
        RETURN NEW
      "

      case client.query(auth_ctx.db, query, [
        #("session_id", json.string(session_id)),
        #("user_key", json.string(user_key)),
        #("now", json.string(now)),
      ], training.training_session_decoder) {
        Ok(result) -> {
          case result.result {
            [session, ..] -> {
              // Calculate session summary
              let total = list.length(session.interventions)
              let correct_count = list.count(session.interventions, fn(r) {
                r.outcome == Correct
              })
              let accuracy = case total > 0 {
                True -> int.to_float(correct_count) /. int.to_float(total)
                False -> 0.0
              }

              json.object([
                #("session", training.training_session_to_json(session)),
                #("summary", json.object([
                  #("total_interventions", json.int(total)),
                  #("correct_responses", json.int(correct_count)),
                  #("accuracy", json.float(accuracy)),
                ])),
              ])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            [] -> error_response("Session not found", 404)
          }
        }
        Error(_) -> error_response("Failed to end session", 500)
      }
    }
    _ -> wisp.method_not_allowed([http.Post])
  }
}

/// GET /api/training/competence - Get user's competence model
pub fn get_competence(req: Request, auth_ctx: AuthContext) -> Response {
  case req.method {
    http.Get -> {
      let user_key = auth_ctx.current_user.key |> option.unwrap("")

      // Default to car domain
      case get_competence_model(auth_ctx, user_key, Car) {
        Ok(model) -> {
          json.object([
            #("competence_model", training.competence_model_to_json(model)),
          ])
          |> json.to_string_builder
          |> wisp.json_response(200)
        }
        Error(_) -> {
          // Create a new one
          let _ = ensure_competence_model(auth_ctx, user_key, Car)
          case get_competence_model(auth_ctx, user_key, Car) {
            Ok(model) -> {
              json.object([
                #("competence_model", training.competence_model_to_json(model)),
              ])
              |> json.to_string_builder
              |> wisp.json_response(200)
            }
            Error(_) -> error_response("Failed to get competence model", 500)
          }
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

fn ensure_competence_model(auth_ctx: AuthContext, user_key: String, domain: VehicleDomain) -> Result(CompetenceModel, Nil) {
  let now = birl.now() |> birl.to_iso8601
  let skill_ids = get_default_skills() |> list.map(fn(s) { s.id })

  // Check if exists
  let query = "
    FOR m IN competence_models
    FILTER m.user_key == @user_key AND m.domain == @domain
    RETURN m
  "

  case client.query(auth_ctx.db, query, [
    #("user_key", json.string(user_key)),
    #("domain", json.string(training.domain_to_string(domain))),
  ], training.competence_model_decoder) {
    Ok(result) -> {
      case result.result {
        [model, ..] -> Ok(model)
        [] -> {
          // Create new model
          let skills = skill_ids |> list.map(training.new_skill_state)
          let model_json = json.object([
            #("user_key", json.string(user_key)),
            #("domain", json.string(training.domain_to_string(domain))),
            #("skills", json.array(skills, training.skill_state_to_json)),
            #("created_at", json.string(now)),
            #("updated_at", json.string(now)),
          ])

          case client.insert_document(
            auth_ctx.db,
            "competence_models",
            model_json,
            training.competence_model_decoder,
          ) {
            Ok(m) -> Ok(m)
            Error(_) -> Error(Nil)
          }
        }
      }
    }
    Error(_) -> Error(Nil)
  }
}

fn get_competence_model(auth_ctx: AuthContext, user_key: String, domain: VehicleDomain) -> Result(CompetenceModel, Nil) {
  let query = "
    FOR m IN competence_models
    FILTER m.user_key == @user_key AND m.domain == @domain
    RETURN m
  "

  case client.query(auth_ctx.db, query, [
    #("user_key", json.string(user_key)),
    #("domain", json.string(training.domain_to_string(domain))),
  ], training.competence_model_decoder) {
    Ok(result) -> {
      case result.result {
        [model, ..] -> Ok(model)
        [] -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

fn update_competence_after_intervention(
  auth_ctx: AuthContext,
  user_key: String,
  domain: VehicleDomain,
  skill_id: String,
  outcome: Outcome,
  now: String,
) -> Result(Nil, Nil) {
  // Get current model
  case get_competence_model(auth_ctx, user_key, domain) {
    Ok(model) -> {
      // Update the specific skill
      let updated_skills = list.map(model.skills, fn(skill) {
        case skill.skill_id == skill_id {
          True -> training.update_skill_after_intervention(skill, outcome, now)
          False -> skill
        }
      })

      // Save updated model
      let update_query = "
        FOR m IN competence_models
        FILTER m.user_key == @user_key AND m.domain == @domain
        UPDATE m WITH {
          skills: @skills,
          updated_at: @now
        } IN competence_models
        RETURN NEW
      "

      case client.query(auth_ctx.db, update_query, [
        #("user_key", json.string(user_key)),
        #("domain", json.string(training.domain_to_string(domain))),
        #("skills", json.array(updated_skills, training.skill_state_to_json)),
        #("now", json.string(now)),
      ], training.competence_model_decoder) {
        Ok(_) -> Ok(Nil)
        Error(_) -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

fn select_best_skill(skills: List(SkillState)) -> Option(SkillState) {
  skills
  |> list.sort(fn(a, b) {
    float.compare(
      training.calculate_learning_value(b),
      training.calculate_learning_value(a),
    )
  })
  |> list.first
  |> option.from_result
}

fn generate_gap_timing_intervention(skill: SkillState, sequence: Int) -> Intervention {
  let difficulty = training.calculate_difficulty(skill)

  // Gap duration scales inversely with difficulty
  // Easy: 3000ms gap, Hard: 1000ms gap
  let gap_duration = float.round(3000.0 -. difficulty *. 2000.0)
  let approach_duration = 2000  // 2 seconds of approach sound

  let gap_start = approach_duration
  let gap_end = approach_duration + gap_duration

  let id = "gap_timing_"
    <> int.to_string(sequence)
    <> "_difficulty_"
    <> int.to_string(float.round(difficulty *. 100.0))
    <> "_gap_"
    <> int.to_string(gap_start)
    <> "_"
    <> int.to_string(gap_end)

  training.Intervention(
    id: id,
    target_skill_id: skill.skill_id,
    modality: Audio,
    difficulty: difficulty,
    content: GapTiming(
      gap_start_ms: gap_start,
      gap_end_ms: gap_end,
      approach_duration_ms: approach_duration,
    ),
    expected_duration_ms: gap_end + 2000,  // Gap end + buffer
  )
}

fn evaluate_gap_timing_response(response_ms: Int, gap_start: Int, gap_end: Int) -> Outcome {
  case response_ms {
    t if t == 0 -> Timeout
    t if t < gap_start -> Incorrect  // Too early
    t if t > gap_end -> Incorrect    // Too late
    _ -> Correct                      // Within gap window
  }
}

fn get_feedback_message(outcome: Outcome, response_ms: Int, gap_start: Int, gap_end: Int) -> String {
  case outcome {
    Correct -> "Excellent! You identified the gap correctly at " <> int.to_string(response_ms) <> "ms."
    Incorrect -> {
      case response_ms < gap_start {
        True -> "Too early! You responded at " <> int.to_string(response_ms) <> "ms, but the gap started at " <> int.to_string(gap_start) <> "ms."
        False -> "Too late! You responded at " <> int.to_string(response_ms) <> "ms, but the gap ended at " <> int.to_string(gap_end) <> "ms."
      }
    }
    Timeout -> "No response received. Try to identify when the gap occurs."
    Skipped -> "Intervention skipped."
  }
}

fn error_response(message: String, status: Int) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(status)
}
