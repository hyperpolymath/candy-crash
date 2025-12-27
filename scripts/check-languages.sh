#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Hyperpolymath

# Language Policy Enforcement Script
# Run this to check for banned languages in the codebase

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "  Language Policy Enforcement Check"
echo "  Hyperpolymath Standard"
echo "========================================="
echo ""

ERRORS=0
WARNINGS=0

# Function to check for file types
check_banned() {
    local pattern=$1
    local name=$2
    local replacement=$3
    local exclude=${4:-""}

    local find_cmd="find . -name '$pattern' -type f"
    if [ -n "$exclude" ]; then
        find_cmd="$find_cmd $exclude"
    fi

    local count=$(eval "$find_cmd" 2>/dev/null | wc -l)

    if [ "$count" -gt 0 ]; then
        echo -e "${RED}[BANNED]${NC} Found $count $name files. Use $replacement instead."
        eval "$find_cmd" 2>/dev/null | head -10
        if [ "$count" -gt 10 ]; then
            echo "  ... and $((count - 10)) more"
        fi
        ERRORS=$((ERRORS + 1))
        return 1
    else
        echo -e "${GREEN}[OK]${NC} No $name files found."
        return 0
    fi
}

check_warning() {
    local pattern=$1
    local name=$2
    local replacement=$3

    local count=$(find . -name "$pattern" -type f 2>/dev/null | wc -l)

    if [ "$count" -gt 0 ]; then
        echo -e "${YELLOW}[WARN]${NC} Found $count $name files. Consider migrating to $replacement."
        WARNINGS=$((WARNINGS + 1))
        return 1
    else
        echo -e "${GREEN}[OK]${NC} No $name files found."
        return 0
    fi
}

echo "Checking for BANNED languages..."
echo ""

# TypeScript
check_banned "*.ts" "TypeScript" "ReScript" "-not -path './node_modules/*'"
check_banned "*.tsx" "TypeScript JSX" "ReScript" "-not -path './node_modules/*'"

# Go
check_banned "*.go" "Go" "Rust"

# Python (outside salt/)
echo -n "Checking Python files... "
py_count=$(find . -name "*.py" -not -path "./salt/*" -type f 2>/dev/null | wc -l)
if [ "$py_count" -gt 0 ]; then
    echo -e "${RED}[BANNED]${NC} Found $py_count Python files outside salt/. Use ReScript or Rust."
    find . -name "*.py" -not -path "./salt/*" -type f 2>/dev/null | head -5
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}[OK]${NC}"
fi

# Kotlin
check_banned "*.kt" "Kotlin" "Tauri/Dioxus"

# Swift
check_banned "*.swift" "Swift" "Tauri/Dioxus"

# Java
check_banned "*.java" "Java" "Rust/Tauri/Dioxus"

# Dart/Flutter
check_banned "*.dart" "Dart" "Tauri/Dioxus"

echo ""
echo "Checking for legacy files (to be migrated)..."
echo ""

# Ruby (legacy - should be migrated to Gleam)
ruby_count=$(find . -name "*.rb" -type f 2>/dev/null | wc -l)
if [ "$ruby_count" -gt 0 ]; then
    echo -e "${YELLOW}[LEGACY]${NC} Found $ruby_count Ruby files. Should be migrated to Gleam."
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}[OK]${NC} No Ruby files found."
fi

# Gemfile
if [ -f "Gemfile" ]; then
    echo -e "${YELLOW}[LEGACY]${NC} Gemfile exists. Should be migrated to gleam.toml."
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}[OK]${NC} No Gemfile found."
fi

# package.json with dependencies
if [ -f "package.json" ] && grep -q '"dependencies"' package.json 2>/dev/null; then
    echo -e "${YELLOW}[LEGACY]${NC} package.json with dependencies exists. Should use deno.json."
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}[OK]${NC} No package.json with runtime dependencies."
fi

# node_modules
if [ -d "node_modules" ]; then
    echo -e "${YELLOW}[LEGACY]${NC} node_modules directory exists. Should use Deno caching."
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}[OK]${NC} No node_modules directory."
fi

echo ""
echo "Checking for ALLOWED languages..."
echo ""

# Gleam
gleam_count=$(find . -name "*.gleam" -type f 2>/dev/null | wc -l)
echo -e "${GREEN}[ALLOWED]${NC} Found $gleam_count Gleam files."

# ReScript
res_count=$(find . -name "*.res" -type f 2>/dev/null | wc -l)
echo -e "${GREEN}[ALLOWED]${NC} Found $res_count ReScript files."

# Rust
rs_count=$(find . -name "*.rs" -type f 2>/dev/null | wc -l)
echo -e "${GREEN}[ALLOWED]${NC} Found $rs_count Rust files."

# Shell
sh_count=$(find . -name "*.sh" -type f 2>/dev/null | wc -l)
echo -e "${GREEN}[ALLOWED]${NC} Found $sh_count Shell scripts."

echo ""
echo "========================================="
echo "  Summary"
echo "========================================="
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}FAILED:${NC} $ERRORS banned language violations found."
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}PASSED WITH WARNINGS:${NC} $WARNINGS legacy items to migrate."
    exit 0
else
    echo -e "${GREEN}PASSED:${NC} All language policy checks passed!"
    exit 0
fi
