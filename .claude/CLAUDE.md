# Candy Crash - Project Instructions

## What This Project Is

Candy Crash is a **total pervasive ambient computing framework** for training vehicle operators (cars, motorbikes, aircraft, watercraft).

This is NOT:
- An LMS (Learning Management System)
- A quiz platform
- Traditional e-learning

This IS:
- An environmental intervention system
- Continuous ambient training that pervades daily life
- Sensor/actuator mesh for competence cultivation
- Privacy-first, trainee-sovereign architecture

See `README.adoc` for the philosophical foundation.
See `PLAN.adoc` for the implementation roadmap.

## Current State

The repository contains legacy code from a misguided earlier approach (Rails LMS). This code will be removed and replaced with the correct architecture.

## Language & Technology Policy (RSR)

### Required Languages

- **Core Runtime**: Rust
  - Real-time sensor/actuator processing
  - Memory-safe systems code
  - Embedded deployment

- **User Interfaces**: ReScript
  - Type-safe web interfaces
  - Configuration and monitoring dashboards
  - Compiles to efficient JavaScript

- **Safety-Critical Components**: SPARK/Ada
  - Formal verification required
  - Provable absence of runtime errors
  - Aviation-adjacent certification requirements

- **ML/Inference**: Rust + WASM
  - On-device competence modeling
  - Privacy-preserving (no cloud dependency)
  - Portable via WebAssembly

### Forbidden

- **Ruby**: Legacy, being removed
- **Python**: Not permitted (except SaltStack)
- **TypeScript/JavaScript**: Use ReScript instead
- **New Java/Kotlin**: Not permitted

### Package Management

- **Primary**: Guix (guix.scm)
- **Fallback**: Nix (flake.nix)

## Security Requirements

- No MD5/SHA1 for security purposes (use SHA256+)
- HTTPS only (no HTTP URLs)
- No hardcoded secrets
- All data encrypted at rest
- Local-first architecture (no cloud dependency for core function)
- Trainee data sovereignty (trainee controls all their data)

## Architecture Principles

### Privacy-First

The system has unprecedented access to the trainee's life. Therefore:

1. All processing happens on trainee-controlled devices
2. No data leaves the local environment without explicit consent
3. Data minimization: collect only what's needed, discard quickly
4. Trainee can pause, export, or delete all data at any time

### Sensor/Actuator Abstraction

All hardware interfaces are abstracted:

```rust
trait SensorSource {
    fn capabilities(&self) -> SensorCapabilities;
    fn subscribe(&self, callback: SensorCallback);
}

trait ActuatorSink {
    fn capabilities(&self) -> ActuatorCapabilities;
    fn send(&self, command: ActuatorCommand) -> Result<()>;
}
```

### Competence Modeling

The system models trainee competence as a multidimensional landscape of micro-skills, not linear progression through content.

### Intervention Planning

The system plans micro-interventions based on:
- Current trainee state (alertness, context, receptivity)
- Competence gaps (what needs training)
- Available modalities (what actuators are present)
- Spaced repetition (optimal timing)

## Directory Structure (Target)

```
candy-crash/
├── core/                    # Rust core intelligence
│   ├── state-perception/    # Trainee state modeling
│   ├── competence-model/    # Skill modeling
│   ├── intervention/        # Planning engine
│   └── storage/             # Local persistence
├── sensors/                 # Sensor integrations
│   ├── smartphone/          # iOS/Android apps
│   ├── wearable/            # Fitness device integration
│   └── vehicle/             # OBD-II, NMEA, etc.
├── actuators/               # Actuator integrations
│   ├── audio/               # Spatial audio rendering
│   ├── haptic/              # Vibration/force feedback
│   └── visual/              # AR overlays
├── domains/                 # Vehicle-specific modules
│   ├── car/                 # Ground vehicle training
│   ├── motorcycle/          # Two-wheel training
│   ├── aircraft/            # Aviation training
│   └── watercraft/          # Marine training
├── ui/                      # ReScript web interfaces
│   ├── config/              # System configuration
│   ├── dashboard/           # Competence visualization
│   └── control/             # Training control
└── docs/                    # Documentation
    ├── competence-model/    # Domain competence specs
    ├── hardware/            # Sensor/actuator requirements
    ├── privacy/             # Privacy architecture
    └── ethics/              # Ethical framework
```

## Contributing Guidelines

Contributors need cross-disciplinary expertise:

- Embodied cognition / ecological psychology
- Pervasive/ubiquitous computing
- Real-time systems engineering
- Human factors / ergonomics
- Vehicle operation (domain expertise)
- Privacy-preserving system design

## DO NOT

- Create traditional "lessons" or "courses"
- Add quiz/assessment content
- Build progress bars or completion tracking
- Add gamification (points, badges, streaks)
- Create cloud dependencies
- Compromise trainee privacy
- Use attention-capturing dark patterns

## DO

- Think about perception-action loops
- Consider what can be trained ambiently
- Respect trainee sovereignty
- Design for the training to disappear
- Focus on genuine competence, not engagement metrics
