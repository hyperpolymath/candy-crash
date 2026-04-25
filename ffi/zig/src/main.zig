const std = @import("std");

// SPDX-License-Identifier: PMPL-1.0-or-later
// C-compatible ABI implementation for Candy Crash training capability registry

pub const ResultCode = enum(u32) {
    Success = 0,
    ErrorAuth = 1,
    ErrorInvalid = 2,
    ErrorTimeout = 3,
};

/// Exported FFI initialization function
export fn candy_crash_init() ?*anyopaque {
    // In a real implementation, this would allocate context
    return @ptrFromInt(0xDEADBEEF);
}

/// Exported FFI cleanup
export fn candy_crash_free(handle: ?*anyopaque) void {
    _ = handle;
}

/// Exported FFI start session capability
export fn candy_crash_start_session(handle: ?*anyopaque) ResultCode {
    if (handle == null) return .ErrorInvalid;
    // FFI stub for starting a training session via Groove
    return .Success;
}
