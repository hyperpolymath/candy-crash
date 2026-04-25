# Candy Crash Safety-Critical Implementation Plan

## Phase 1: Safety Core Implementation (SPARK/Ada)

### 1.1 Directory Structure Setup
```bash
mkdir -p src/safety_core/spark
mkdir -p src/safety_core/ffi/zig
mkdir -p src/safety_core/ffi/rust
mkdir -p src/safety_core/shared
```

### 1.2 SPARK Guardian Module
- **File**: `src/safety_core/spark/guardian.adb`
- **Purpose**: Telemetry validation (cryptographic + hardware range checks)
- **Dependencies**: SHA256 implementation, system interfaces
- **Verification**: Formal proof of packet validation correctness

### 1.3 SPARK Watchdog Module
- **File**: `src/safety_core/spark/watchdog.adb`
- **Purpose**: Hardware monitoring and emergency stop
- **Dependencies**: Real-time clock, HAL interfaces
- **Verification**: Proof of timely emergency response

### 1.4 Shared Memory Protocol
- **File**: `src/safety_core/shared/telemetry.ads`
- **Purpose**: Data structures for cross-language communication
- **Content**: Telemetry packet definitions, shared buffers

## Phase 2: FFI Bridge Implementation

### 2.1 Zig FFI Bindings
- **File**: `src/safety_core/ffi/zig/guardian.zig`
- **Purpose**: Safe bridge between AffineScript and SPARK
- **Content**: Memory-safe wrappers, error handling

### 2.2 Rust FFI Bindings
- **File**: `src/safety_core/ffi/rust/lib.rs`
- **Purpose**: Alternative bridge for Rust components
- **Content**: Safe Rust abstractions over SPARK functions

## Phase 3: AffineScript Safety Integration

### 3.1 Enhanced Actuator System
- **File**: `frontend/src/Safety.as`
- **Purpose**: Resource-safe actuator commands
- **Content**: Priority levels, source tracking, safety checks

### 3.2 Emergency System
- **File**: `frontend/src/Emergency.as`
- **Purpose**: Critical failure handling
- **Content**: Physical power cut, audit logging, notifications

### 3.3 Watchdog Integration
- **File**: `frontend/src/Watchdog.as`
- **Purpose**: Hardware watchdog feeding
- **Content**: Periodic heartbeat, failure detection

## Phase 4: Accessibility Implementation

### 4.1 Sensory Substitution
- **File**: `frontend/src/Accessibility.as`
- **Purpose**: Cross-modal sensory mapping
- **Content**: Audio→Haptic, Visual→Audio, neurodiversity support

### 4.2 Vigilance Monitoring
- **File**: `frontend/src/Neurodiversity.as`
- **Purpose**: Cognitive load management
- **Content**: Response variability, microsaccade analysis

## Phase 5: Encrypted Telemetry System

### 5.1 Hybrid Encryption
- **File**: `backend/src/telemetry.gleam`
- **Purpose**: Secure telemetry processing
- **Content**: RSA key exchange, AES-GCM encryption, HMAC validation

### 5.2 Packet Processing
- **File**: `backend/src/packet_processor.gleam`
- **Purpose**: Telemetry pipeline
- **Content**: Decryption, validation, routing

## Phase 6: Testing and Verification

### 6.1 Unit Tests
- **Files**: `tests/safety_core_test.*`
- **Purpose**: Module-level verification
- **Content**: Guardian validation, watchdog timing, FFI safety

### 6.2 Integration Tests
- **Files**: `tests/integration_test.*`
- **Purpose**: System-level verification
- **Content**: Mode handover, emergency sequences, sensory substitution

### 6.3 Formal Verification
- **Files**: `proofs/*.gpr`
- **Purpose**: Mathematical proof of safety
- **Content**: SPARK proof objectives, invariant verification

## Implementation Timeline

1. **Week 1**: SPARK safety core (guardian + watchdog)
2. **Week 2**: FFI bridges (Zig + Rust)
3. **Week 3**: AffineScript safety integration
4. **Week 4**: Accessibility systems
5. **Week 5**: Encrypted telemetry
6. **Week 6**: Testing and verification

## Questions for Review

1. Should I use GNAT Pro for SPARK verification or open-source tools?
2. What specific GPIO interfaces should I target for hardware control?
3. Should I implement ephemeral Diffie-Hellman or pre-shared keys?
4. What key sizes should I use (RSA-2048, AES-256)?
5. Should I create hardware-in-the-loop tests or focus on software simulation first?

## Next Steps

1. Implement SPARK guardian module
2. Create FFI bridge layer
3. Integrate with existing AffineScript code
4. Add accessibility features
5. Implement encrypted telemetry
6. Comprehensive testing
