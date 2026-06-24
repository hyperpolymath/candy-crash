#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
#
# Install Git hooks for Candy Crash
# Usage: ./.githooks/install.sh

set -e

echo "🔧 Installing Git hooks..."

# Method 1: Use git config to set hooks path (Git 2.9+)
if git config core.hooksPath .githooks; then
    echo "✓ Git hooks path set to .githooks"
    echo "✓ Hooks will run automatically on commit and push"
else
    # Method 2: Fallback to copying hooks (older Git versions)
    echo "⚠️  Could not set hooks path, copying hooks manually..."
    cp .githooks/pre-commit .git/hooks/pre-commit
    cp .githooks/pre-push .git/hooks/pre-push
    chmod +x .git/hooks/pre-commit .git/hooks/pre-push
    echo "✓ Hooks copied to .git/hooks/"
fi

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "The following hooks are now active:"
echo "  • pre-commit:  Linting, SPDX headers, debugging checks"
echo "  • pre-push:    Tests, security scans, dependency audits"
echo ""
echo "To skip hooks temporarily (not recommended):"
echo "  git commit --no-verify"
echo "  git push --no-verify"
echo ""
