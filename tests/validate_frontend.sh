#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# validate_frontend.sh — checks frontend/ directory structure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND="$REPO_ROOT/frontend"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== candy-crash: frontend structure check ==="

if [ ! -d "$FRONTEND" ]; then
    fail "frontend/ directory does not exist"
    echo "Results: $PASS passed, $FAIL failed"
    exit 1
fi
pass "frontend/ directory exists"

# Check for a src/ subdirectory or index.html
if [ -d "$FRONTEND/src" ] || [ -f "$FRONTEND/index.html" ]; then
    pass "frontend has src/ or index.html"
else
    fail "frontend/ has neither src/ nor index.html"
fi

# Check for a project config file (deno.json, rescript.json, or package.json)
config_found=0
for config in deno.json rescript.json package.json; do
    if [ -f "$FRONTEND/$config" ]; then
        pass "frontend/$config found"
        config_found=1
        break
    fi
done
if [ "$config_found" -eq 0 ]; then
    fail "no project config (deno.json / rescript.json / package.json) in frontend/"
fi

# Check that frontend/src/ has at least one source file if src/ exists
if [ -d "$FRONTEND/src" ]; then
    src_count=$(find "$FRONTEND/src" -maxdepth 2 -type f | wc -l)
    if [ "$src_count" -gt 0 ]; then
        pass "frontend/src/ contains $src_count source file(s)"
    else
        fail "frontend/src/ is empty"
    fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
