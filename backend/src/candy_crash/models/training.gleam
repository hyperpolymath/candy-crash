// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result

// ============================================================================
// Domain Types
// ============================================================================

pub type VehicleDomain {
  Car
  Motorcycle
  Aircraft
  Watercraft
}

pub type SALevel {
  Perception
  Comprehension
  Projection
}

pub type Activity {
  Walking
  Sitting
  Passenger
  Driving
  Sleeping
  Unknown
}

pub type AttentionLevel {
  Available
  Partial
  Unavailable
}

pub type Modality {
  Audio
  Visual
  Haptic
}

pub type Outcome {
  Correct
  Incorrect
  Timeout
  Skipped
}

// ============================================================================
// Micro-Skill Definition
// ============================================================================

pub type MicroSkill {
  MicroSkill(
    id: String,
    name: String,
    description: String,
    domain: VehicleDomain,
    sa_level: SALevel,
    ambient_trainable: Bool,
    modalities: List(Modality),
  )
}

// ============================================================================
// Competence Model
// ============================================================================

pub type SkillState {
  SkillState(
    skill_id: String,
    competence: Float,
    confidence: Float,
    last_trained: Option(String),
    last_assessed: Option(String),
    attempt_count: Int,
    success_count: Int,
  )
}

pub type CompetenceModel {
  CompetenceModel(
    key: Option(String),
    user_key: String,
    domain: VehicleDomain,
    skills: List(SkillState),
    created_at: Option(String),
    updated_at: Option(String),
  )
}

// ============================================================================
// Trainee State
// ============================================================================

pub type TraineeState {
  TraineeState(
    activity: Activity,
    attention: AttentionLevel,
    last_intervention_at: Option(String),
    session_intervention_count: Int,
  )
}

// ============================================================================
// Intervention
// ============================================================================

pub type InterventionContent {
  GapTiming(gap_start_ms: Int, gap_end_ms: Int, approach_duration_ms: Int)
  HazardPrediction(scenario: String, correct_time_ms: Int)
  MirrorCheck(direction: String, expected_interval_ms: Int)
  SpeedEstimation(actual_speed: Int, tolerance: Int)
}

pub type Intervention {
  Intervention(
    id: String,
    target_skill_id: String,
    modality: Modality,
    difficulty: Float,
    content: InterventionContent,
    expected_duration_ms: Int,
  )
}

// ============================================================================
// Training Session
// ============================================================================

pub type SessionStatus {
  SessionActive
  SessionPaused
  SessionCompleted
}

pub type InterventionResult {
  InterventionResult(
    intervention_id: String,
    delivered_at: String,
    response_time_ms: Option(Int),
    outcome: Outcome,
  )
}

pub type TrainingSession {
  TrainingSession(
    key: Option(String),
    user_key: String,
    domain: VehicleDomain,
    started_at: String,
    ended_at: Option(String),
    status: SessionStatus,
    initial_activity: Activity,
    interventions: List(InterventionResult),
  )
}

// ============================================================================
// Attention Budget
// ============================================================================

pub type AttentionBudget {
  AttentionBudget(
    max_interventions_per_hour: Int,
    min_spacing_seconds: Int,
    walking_multiplier: Float,
    sitting_multiplier: Float,
    passenger_multiplier: Float,
  )
}

pub fn default_attention_budget() -> AttentionBudget {
  AttentionBudget(
    max_interventions_per_hour: 12,
    min_spacing_seconds: 180,
    walking_multiplier: 0.6,
    sitting_multiplier: 1.0,
    passenger_multiplier: 0.8,
  )
}

// ============================================================================
// String Conversions
// ============================================================================

pub fn domain_to_string(d: VehicleDomain) -> String {
  case d {
    Car -> "car"
    Motorcycle -> "motorcycle"
    Aircraft -> "aircraft"
    Watercraft -> "watercraft"
  }
}

pub fn domain_from_string(s: String) -> VehicleDomain {
  case s {
    "motorcycle" -> Motorcycle
    "aircraft" -> Aircraft
    "watercraft" -> Watercraft
    _ -> Car
  }
}

pub fn sa_level_to_string(s: SALevel) -> String {
  case s {
    Perception -> "perception"
    Comprehension -> "comprehension"
    Projection -> "projection"
  }
}

pub fn sa_level_from_string(s: String) -> SALevel {
  case s {
    "comprehension" -> Comprehension
    "projection" -> Projection
    _ -> Perception
  }
}

pub fn activity_to_string(a: Activity) -> String {
  case a {
    Walking -> "walking"
    Sitting -> "sitting"
    Passenger -> "passenger"
    Driving -> "driving"
    Sleeping -> "sleeping"
    Unknown -> "unknown"
  }
}

pub fn activity_from_string(s: String) -> Activity {
  case s {
    "walking" -> Walking
    "sitting" -> Sitting
    "passenger" -> Passenger
    "driving" -> Driving
    "sleeping" -> Sleeping
    _ -> Unknown
  }
}

pub fn attention_to_string(a: AttentionLevel) -> String {
  case a {
    Available -> "available"
    Partial -> "partial"
    Unavailable -> "unavailable"
  }
}

pub fn attention_from_string(s: String) -> AttentionLevel {
  case s {
    "available" -> Available
    "partial" -> Partial
    _ -> Unavailable
  }
}

pub fn modality_to_string(m: Modality) -> String {
  case m {
    Audio -> "audio"
    Visual -> "visual"
    Haptic -> "haptic"
  }
}

pub fn modality_from_string(s: String) -> Modality {
  case s {
    "visual" -> Visual
    "haptic" -> Haptic
    _ -> Audio
  }
}

pub fn outcome_to_string(o: Outcome) -> String {
  case o {
    Correct -> "correct"
    Incorrect -> "incorrect"
    Timeout -> "timeout"
    Skipped -> "skipped"
  }
}

pub fn outcome_from_string(s: String) -> Outcome {
  case s {
    "correct" -> Correct
    "incorrect" -> Incorrect
    "timeout" -> Timeout
    _ -> Skipped
  }
}

pub fn session_status_to_string(s: SessionStatus) -> String {
  case s {
    SessionActive -> "active"
    SessionPaused -> "paused"
    SessionCompleted -> "completed"
  }
}

pub fn session_status_from_string(s: String) -> SessionStatus {
  case s {
    "paused" -> SessionPaused
    "completed" -> SessionCompleted
    _ -> SessionActive
  }
}

// ============================================================================
// JSON Encoders
// ============================================================================

pub fn skill_state_to_json(s: SkillState) -> Json {
  json.object([
    #("skill_id", json.string(s.skill_id)),
    #("competence", json.float(s.competence)),
    #("confidence", json.float(s.confidence)),
    #("last_trained", case s.last_trained {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("last_assessed", case s.last_assessed {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("attempt_count", json.int(s.attempt_count)),
    #("success_count", json.int(s.success_count)),
  ])
}

pub fn competence_model_to_json(m: CompetenceModel) -> Json {
  json.object([
    #("key", case m.key {
      Some(k) -> json.string(k)
      None -> json.null()
    }),
    #("user_key", json.string(m.user_key)),
    #("domain", json.string(domain_to_string(m.domain))),
    #("skills", json.array(m.skills, skill_state_to_json)),
    #("created_at", case m.created_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("updated_at", case m.updated_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
  ])
}

pub fn trainee_state_to_json(s: TraineeState) -> Json {
  json.object([
    #("activity", json.string(activity_to_string(s.activity))),
    #("attention", json.string(attention_to_string(s.attention))),
    #("last_intervention_at", case s.last_intervention_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("session_intervention_count", json.int(s.session_intervention_count)),
  ])
}

pub fn intervention_content_to_json(c: InterventionContent) -> Json {
  case c {
    GapTiming(gap_start, gap_end, approach) ->
      json.object([
        #("type", json.string("gap_timing")),
        #("gap_start_ms", json.int(gap_start)),
        #("gap_end_ms", json.int(gap_end)),
        #("approach_duration_ms", json.int(approach)),
      ])
    HazardPrediction(scenario, time) ->
      json.object([
        #("type", json.string("hazard_prediction")),
        #("scenario", json.string(scenario)),
        #("correct_time_ms", json.int(time)),
      ])
    MirrorCheck(dir, interval) ->
      json.object([
        #("type", json.string("mirror_check")),
        #("direction", json.string(dir)),
        #("expected_interval_ms", json.int(interval)),
      ])
    SpeedEstimation(speed, tolerance) ->
      json.object([
        #("type", json.string("speed_estimation")),
        #("actual_speed", json.int(speed)),
        #("tolerance", json.int(tolerance)),
      ])
  }
}

pub fn intervention_to_json(i: Intervention) -> Json {
  json.object([
    #("id", json.string(i.id)),
    #("target_skill_id", json.string(i.target_skill_id)),
    #("modality", json.string(modality_to_string(i.modality))),
    #("difficulty", json.float(i.difficulty)),
    #("content", intervention_content_to_json(i.content)),
    #("expected_duration_ms", json.int(i.expected_duration_ms)),
  ])
}

pub fn intervention_result_to_json(r: InterventionResult) -> Json {
  json.object([
    #("intervention_id", json.string(r.intervention_id)),
    #("delivered_at", json.string(r.delivered_at)),
    #("response_time_ms", case r.response_time_ms {
      Some(t) -> json.int(t)
      None -> json.null()
    }),
    #("outcome", json.string(outcome_to_string(r.outcome))),
  ])
}

pub fn training_session_to_json(s: TrainingSession) -> Json {
  json.object([
    #("key", case s.key {
      Some(k) -> json.string(k)
      None -> json.null()
    }),
    #("user_key", json.string(s.user_key)),
    #("domain", json.string(domain_to_string(s.domain))),
    #("started_at", json.string(s.started_at)),
    #("ended_at", case s.ended_at {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("status", json.string(session_status_to_string(s.status))),
    #("initial_activity", json.string(activity_to_string(s.initial_activity))),
    #("interventions", json.array(s.interventions, intervention_result_to_json)),
  ])
}

pub fn micro_skill_to_json(s: MicroSkill) -> Json {
  json.object([
    #("id", json.string(s.id)),
    #("name", json.string(s.name)),
    #("description", json.string(s.description)),
    #("domain", json.string(domain_to_string(s.domain))),
    #("sa_level", json.string(sa_level_to_string(s.sa_level))),
    #("ambient_trainable", json.bool(s.ambient_trainable)),
    #("modalities", json.array(s.modalities, fn(m) {
      json.string(modality_to_string(m))
    })),
  ])
}

// ============================================================================
// JSON Decoders
// ============================================================================

pub fn skill_state_decoder(dyn: Dynamic) -> Result(SkillState, List(DecodeError)) {
  dynamic.decode7(
    SkillState,
    dynamic.field("skill_id", dynamic.string),
    dynamic.field("competence", dynamic.float),
    dynamic.field("confidence", dynamic.float),
    dynamic.optional_field("last_trained", dynamic.string),
    dynamic.optional_field("last_assessed", dynamic.string),
    dynamic.field("attempt_count", dynamic.int),
    dynamic.field("success_count", dynamic.int),
  )(dyn)
}

pub fn competence_model_decoder(dyn: Dynamic) -> Result(CompetenceModel, List(DecodeError)) {
  dynamic.decode6(
    CompetenceModel,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("user_key", dynamic.string),
    dynamic.field("domain", fn(d) {
      dynamic.string(d)
      |> result.map(domain_from_string)
    }),
    dynamic.field("skills", dynamic.list(skill_state_decoder)),
    dynamic.optional_field("created_at", dynamic.string),
    dynamic.optional_field("updated_at", dynamic.string),
  )(dyn)
}

pub fn intervention_result_decoder(dyn: Dynamic) -> Result(InterventionResult, List(DecodeError)) {
  dynamic.decode4(
    InterventionResult,
    dynamic.field("intervention_id", dynamic.string),
    dynamic.field("delivered_at", dynamic.string),
    dynamic.optional_field("response_time_ms", dynamic.int),
    dynamic.field("outcome", fn(d) {
      dynamic.string(d)
      |> result.map(outcome_from_string)
    }),
  )(dyn)
}

pub fn training_session_decoder(dyn: Dynamic) -> Result(TrainingSession, List(DecodeError)) {
  dynamic.decode8(
    TrainingSession,
    dynamic.optional_field("_key", dynamic.string),
    dynamic.field("user_key", dynamic.string),
    dynamic.field("domain", fn(d) {
      dynamic.string(d)
      |> result.map(domain_from_string)
    }),
    dynamic.field("started_at", dynamic.string),
    dynamic.optional_field("ended_at", dynamic.string),
    dynamic.field("status", fn(d) {
      dynamic.string(d)
      |> result.map(session_status_from_string)
    }),
    dynamic.field("initial_activity", fn(d) {
      dynamic.string(d)
      |> result.map(activity_from_string)
    }),
    dynamic.field("interventions", dynamic.list(intervention_result_decoder)),
  )(dyn)
}

// ============================================================================
// Constructors
// ============================================================================

pub fn new_skill_state(skill_id: String) -> SkillState {
  SkillState(
    skill_id: skill_id,
    competence: 0.0,
    confidence: 0.0,
    last_trained: None,
    last_assessed: None,
    attempt_count: 0,
    success_count: 0,
  )
}

pub fn new_competence_model(user_key: String, domain: VehicleDomain, skill_ids: List(String)) -> CompetenceModel {
  let skills = skill_ids
    |> gleam/list.map(new_skill_state)

  CompetenceModel(
    key: None,
    user_key: user_key,
    domain: domain,
    skills: skills,
    created_at: None,
    updated_at: None,
  )
}

pub fn new_training_session(user_key: String, domain: VehicleDomain, started_at: String, activity: Activity) -> TrainingSession {
  TrainingSession(
    key: None,
    user_key: user_key,
    domain: domain,
    started_at: started_at,
    ended_at: None,
    status: SessionActive,
    initial_activity: activity,
    interventions: [],
  )
}

pub fn new_trainee_state(activity: Activity) -> TraineeState {
  TraineeState(
    activity: activity,
    attention: case activity {
      Walking -> Partial
      Sitting -> Available
      Passenger -> Partial
      Driving -> Unavailable
      Sleeping -> Unavailable
      Unknown -> Unavailable
    },
    last_intervention_at: None,
    session_intervention_count: 0,
  )
}

// ============================================================================
// Training Loop Logic
// ============================================================================

/// Check if the current moment is suitable for training
pub fn is_trainable_moment(state: TraineeState, budget: AttentionBudget) -> Bool {
  case state.attention {
    Unavailable -> False
    _ -> {
      // Check intervention count limit (simplified hourly check)
      state.session_intervention_count < budget.max_interventions_per_hour
    }
  }
}

/// Calculate learning value for a skill (higher = should train this)
pub fn calculate_learning_value(skill: SkillState) -> Float {
  let competence_gap = 1.0 -. skill.competence
  let confidence_weight = 1.0 -. skill.confidence

  // Simple multiplication of factors
  competence_gap *. confidence_weight
}

/// Calculate difficulty based on current competence
pub fn calculate_difficulty(skill: SkillState) -> Float {
  // Target 70% success rate
  let success_rate = case skill.attempt_count > 0 {
    True -> int.to_float(skill.success_count) /. int.to_float(skill.attempt_count)
    False -> 0.5  // Start at medium difficulty
  }

  let base = skill.competence

  case success_rate {
    rate if rate >. 0.85 -> float.min(1.0, base +. 0.1)
    rate if rate <. 0.55 -> float.max(0.0, base -. 0.1)
    _ -> base
  }
}

/// Update skill state after intervention
pub fn update_skill_after_intervention(
  skill: SkillState,
  outcome: Outcome,
  now: String,
) -> SkillState {
  let new_attempt_count = skill.attempt_count + 1
  let new_success_count = case outcome {
    Correct -> skill.success_count + 1
    _ -> skill.success_count
  }

  // Simple Bayesian-ish update
  let success_rate = int.to_float(new_success_count) /. int.to_float(new_attempt_count)

  // Competence moves toward success rate
  let new_competence = skill.competence *. 0.8 +. success_rate *. 0.2

  // Confidence increases with more attempts
  let new_confidence = float.min(1.0, skill.confidence +. 0.1)

  SkillState(
    ..skill,
    competence: new_competence,
    confidence: new_confidence,
    last_trained: Some(now),
    attempt_count: new_attempt_count,
    success_count: new_success_count,
  )
}

// Import list module
import gleam/list
