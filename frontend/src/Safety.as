// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 Hyperpolymath
//
// Safety-Critical Actuator System
// Resource-safe commands with priority and source tracking

import AffineLinear;
import AffineFFI;

// Actuator identifiers
type ActuatorID
  | BeltTensioner
  | GSeatFlapLeft
  | GSeatFlapRight
  | SurgeMotor
  | TractionLossSimulator
  | ScentDiffuser1
  | ScentDiffuser2
  | LEDZone1
  | LEDZone2
  | FanController

// Priority levels for emergency handling
type PriorityLevel
  | Critical    // Emergency stop - highest priority
  | High        // Immediate intervention
  | Medium      // Standard feedback
  | Low         // Subtle cues

// Source tracking for audit trail
type TelemetrySource
  | UDP(sequence: UInt32)
  | ManualOverride(userId: String)
  | SystemInit
  | EmergencyProtocol

// Linear resource for hardware safety
resource ActuatorCommand where
  constructor MkCommand
  target: ActuatorID
  intensity: Float      // 0.0 to 1.0
  duration: UInt32      // Milliseconds
  safetyCheck: Bool     // Must be true to execute
  priority: PriorityLevel
  source: TelemetrySource
  timestamp: UInt64     // Unix timestamp in nanoseconds

// Safety validation functions
fn inSafeRange(target: ActuatorID, intensity: Float) -> Bool {
  match target {
    BeltTensioner => intensity >= 0.0 && intensity <= 0.8,  // Max 80% tension
    GSeatFlapLeft | GSeatFlapRight => intensity >= 0.0 && intensity <= 1.0,
    SurgeMotor => intensity >= 0.0 && intensity <= 0.6,    // Max 60% surge
    TractionLossSimulator => intensity >= 0.0 && intensity <= 0.5,  // Max 50%
    ScentDiffuser1 | ScentDiffuser2 => intensity >= 0.0 && intensity <= 1.0,
    LEDZone1 | LEDZone2 => intensity >= 0.0 && intensity <= 1.0,
    FanController => intensity >= 0.0 && intensity <= 1.0
  }
}

fn cooldownExpired(target: ActuatorID, timestamp: UInt64) -> Bool {
  let currentTime = AffineFFI.currentTimeNanos();
  let cooldown = match target {
    BeltTensioner => 500_000_000,  // 500ms cooldown
    GSeatFlapLeft | GSeatFlapRight => 200_000_000,  // 200ms
    SurgeMotor => 1_000_000_000,  // 1000ms
    TractionLossSimulator => 300_000_000,  // 300ms
    ScentDiffuser1 | ScentDiffuser2 => 5_000_000_000,  // 5000ms
    _ => 100_000_000  // 100ms default
  };
  
  currentTime - timestamp > cooldown
}

// Safe command execution with linear resource consumption
fn safeExecute(command: ActuatorCommand) -> Result<(), SafetyError> / AffineLinear {
  // Validate intensity range
  if !inSafeRange(command.target, command.intensity) {
    AffineLinear.consume(command);
    return Err(InvalidIntensity);
  }

  // Check cooldown period
  if !cooldownExpired(command.target, command.timestamp) {
    AffineLinear.consume(command);
    return Err(CooldownActive);
  }

  // Execute through SPARK safety layer
  let result = AffineFFI.guardian_validate_command(command);
  
  match result {
    Ok(_) => {
      AffineFFI.execute_actuator(command);
      AffineLinear.consume(command);  // Command consumed exactly once
      Ok(())
    }
    Err(e) => {
      AffineLinear.consume(command);
      Err(GuardianRejected)
    }
  }
}

// Emergency stop with highest priority
type SafetyError
  | InvalidIntensity
  | CooldownActive
  | GuardianRejected
  | HardwareFailure

fn emergencyStop() -> Cmd<Msg> {
  // Create critical priority command
  let command = MkCommand {
    target: BeltTensioner,
    intensity: 0.0,  // Release all tension
    duration: 0,
    safetyCheck: true,
    priority: Critical,
    source: EmergencyProtocol,
    timestamp: AffineFFI.currentTimeNanos()
  };
  
  // Execute emergency stop through SPARK
  AffineFFI.guardian_emergency_stop();
  
  // Log critical event
  AffineFFI.log_critical_event("EMERGENCY_STOP");
  
  // Return system reset command
  SystemReset
}

// Watchdog feeding
fn feedWatchdog() -> Cmd<Msg> {
  AffineFFI.guardian_feed_watchdog();
  WatchdogFed
}

// Periodic watchdog subscription
fn watchdogSubscriber(interval: UInt32) -> Sub<Msg> {
  Timer.every(interval, fn(_) {
    feedWatchdog()
  })
}