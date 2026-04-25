// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath
//
// Zig FFI Bridge for SPARK Guardian
// Memory-safe interface between AffineScript and SPARK safety core

const std = @import("std");
const c = @cImport({
    @cInclude("guardian.h");
});

// Telemetry packet structure matching SPARK definition
const TelemetryPacket = extern struct {
    data: [64]u8,          // Telemetry data
    hmac: [32]u8,          // HMAC-SHA256 digest
    sequence: u32,         // Packet sequence number
    timestamp: u64,        // Timestamp in nanoseconds
};

// Validation result enum
const ValidationResult = enum {
    Valid,
    Invalid_Signature,
    Invalid_Range,
};

// Guardian FFI interface
pub const Guardian = struct {
    // Validate telemetry packet
    pub fn validateTelemetry(packet: *const TelemetryPacket) ValidationResult {
        const result = c.guardian_validate_telemetry(packet);
        return @enumFromInt(ValidationResult, result);
    }

    // Feed hardware watchdog
    pub fn feedWatchdog() void {
        c.guardian_feed_watchdog();
    }

    // Trigger emergency stop
    pub fn emergencyStop() void {
        c.guardian_emergency_stop();
    }

    // Check watchdog status
    pub fn checkWatchdog() bool {
        return c.guardian_check_watchdog() != 0;
    }

    // Enable watchdog monitoring
    pub fn enableWatchdog() void {
        c.guardian_enable_watchdog();
    }

    // Disable watchdog (for maintenance)
    pub fn disableWatchdog() void {
        c.guardian_disable_watchdog();
    }
};

// Safety wrapper for telemetry validation
pub fn safeValidateTelemetry(
    packet: *const TelemetryPacket
) !ValidationResult {
    // Check for null pointer
    if (packet == null) {
        return error.NullPointer;
    }

    // Validate packet through SPARK guardian
    const result = Guardian.validateTelemetry(packet);

    // Convert to Zig result type
    return result;
}

// Periodic watchdog feeding
pub fn startWatchdogFeeder(allocator: std.mem.Allocator) !std.Thread {
    const thread = try std.Thread.spawn(.{}, watchdogLoop, .{});
    return thread;
}

fn watchdogLoop(_: anytype) void {
    const interval = std.time.ns_per_ms * 5; // 5ms interval
    
    while (true) {
        // Feed watchdog every 5ms
        Guardian.feedWatchdog();
        
        // Check watchdog status
        if (!Guardian.checkWatchdog()) {
            // Watchdog triggered emergency stop
            // Thread will exit
            return;
        }
        
        // Sleep for interval
        std.time.sleep(interval);
    }
}