#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# validate_structure.sh — structural check for candy-crash
# Verifies required files and directories are present.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

check_file() {
    local path="$REPO_ROOT/$1"
    if [ -f "$path" ]; then
        pass "file exists: $1"
    else
        fail "file missing: $1"
    fi
}

check_dir() {
    local path="$REPO_ROOT/$1"
    if [ -d "$path" ]; then
        pass "directory exists: $1"
    else
        fail "directory missing: $1"
    fi
}

echo "=== candy-crash: structural check ==="

check_file "README.adoc"
check_file "LICENSE"
check_file "SECURITY.md"
check_file "ABI-FFI-README.md"
check_dir  "backend"
check_dir  "frontend"
check_dir  "ffi/zig"
check_file "Containerfile"

# .github/workflows must have at least 3 files
WORKFLOW_DIR="$REPO_ROOT/.github/workflows"
if [ -d "$WORKFLOW_DIR" ]; then
    workflow_count=$(find "$WORKFLOW_DIR" -maxdepth 1 \( -name "*.yml" -o -name "*.yaml" \) | wc -l)
    if [ "$workflow_count" -ge 3 ]; then
        pass ".github/workflows has $workflow_count workflow files (>= 3)"
    else
        fail ".github/workflows has only $workflow_count workflow files (need >= 3)"
    fi
else
    fail ".github/workflows directory missing"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
