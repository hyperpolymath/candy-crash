#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Candy Crash Bootstrap Script
# Checks for critical dependencies after cloning
#
# Usage:
#   ./bootstrap.sh
#
# This script checks for:
#   - Git (version control)
#   - Just (task runner)
#   - Podman (container engine)
#   - Ruby (runtime)
#
# NOTE: Git doesn't support "pre-clone" hooks (hooks only exist after clone).
# Users should run this script immediately after cloning.

set -e

echo "🍬 Candy Crash Bootstrap"
echo "======================="
echo ""
echo "Checking critical dependencies..."
echo ""

# Track missing dependencies
missing=()
optional_missing=()

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check Git (should always be present if we got here)
echo -n "Checking Git...           "
if command -v git &> /dev/null; then
    version=$(git --version | awk '{print $3}')
    echo -e "${GREEN}✓${NC} Found (v$version)"
else
    echo -e "${RED}✗${NC} Missing (critical)"
    missing+=("git")
fi

# Check Just (task runner - CRITICAL)
echo -n "Checking Just...          "
if command -v just &> /dev/null; then
    version=$(just --version | awk '{print $2}')
    echo -e "${GREEN}✓${NC} Found (v$version)"
else
    echo -e "${RED}✗${NC} Missing (critical)"
    missing+=("just")
fi

# Check Podman (container engine - CRITICAL for production)
echo -n "Checking Podman...        "
if command -v podman &> /dev/null; then
    version=$(podman --version | awk '{print $3}')
    echo -e "${GREEN}✓${NC} Found (v$version)"
else
    echo -e "${YELLOW}✗${NC} Missing (required for containers)"
    missing+=("podman")
fi

# Check Ruby (runtime - should be present for Rails)
echo -n "Checking Ruby...          "
if command -v ruby &> /dev/null; then
    version=$(ruby --version | awk '{print $2}')
    echo -e "${GREEN}✓${NC} Found (v$version)"

    # Check if it's the right version
    required_version="3.3.6"
    if [[ "$version" != "$required_version"* ]]; then
        echo -e "${YELLOW}⚠${NC}  Warning: Expected Ruby $required_version, found $version"
    fi
else
    echo -e "${RED}✗${NC} Missing (critical)"
    missing+=("ruby")
fi

# Check Bundler (Ruby gem manager)
echo -n "Checking Bundler...       "
if command -v bundle &> /dev/null; then
    version=$(bundle --version | awk '{print $3}')
    echo -e "${GREEN}✓${NC} Found (v$version)"
else
    echo -e "${YELLOW}✗${NC} Missing (install with: gem install bundler)"
    optional_missing+=("bundler")
fi

# Check Deno (JavaScript/TypeScript runtime)
echo -n "Checking Deno...          "
if command -v deno &> /dev/null; then
    version=$(deno --version | head -1 | awk '{print $2}')
    echo -e "${GREEN}✓${NC} Found (v$version)"
else
    echo -e "${YELLOW}✗${NC} Missing (JavaScript runtime)"
    optional_missing+=("deno")
fi

echo ""
echo "======================="
echo ""

# If critical dependencies are missing, prompt for installation
if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}⚠️  CRITICAL DEPENDENCIES MISSING${NC}"
    echo ""
    echo "The following tools are required to work on this project:"
    echo ""

    for dep in "${missing[@]}"; do
        case $dep in
            git)
                echo -e "${BLUE}Git${NC} (version control)"
                echo "  Install: https://git-scm.com/downloads"
                ;;
            just)
                echo -e "${BLUE}Just${NC} (task runner)"
                echo "  Install: cargo install just"
                echo "  Or visit: https://github.com/casey/just#installation"
                echo "  Packages available for: brew, apt, pacman, cargo"
                ;;
            podman)
                echo -e "${BLUE}Podman${NC} (rootless container engine)"
                echo "  Install:"
                echo "    • Ubuntu/Debian: sudo apt-get install podman"
                echo "    • Fedora: sudo dnf install podman"
                echo "    • macOS: brew install podman"
                echo "    • Arch: sudo pacman -S podman"
                echo "  Or visit: https://podman.io/getting-started/installation"
                ;;
            ruby)
                echo -e "${BLUE}Ruby 3.3.6${NC} (runtime)"
                echo "  Install with rbenv:"
                echo "    rbenv install 3.3.6"
                echo "    rbenv global 3.3.6"
                echo "  Or visit: https://www.ruby-lang.org/en/downloads/"
                ;;
        esac
        echo ""
    done

    echo -e "${YELLOW}Without these tools, you will be severely limited in contributing to this project.${NC}"
    echo ""

    # Ask if they want to continue
    read -p "Do you want to continue setup anyway? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Setup aborted. Please install missing dependencies and run ./bootstrap.sh again."
        echo ""
        exit 1
    fi

    echo ""
    echo -e "${YELLOW}⚠️  Continuing with missing dependencies (not recommended)${NC}"
    echo ""
fi

# Install Git hooks if Just is available
if command -v just &> /dev/null; then
    echo "🔧 Setting up Git hooks..."
    if ./.githooks/install.sh; then
        echo -e "${GREEN}✓${NC} Git hooks installed"
    else
        echo -e "${YELLOW}⚠${NC}  Could not install Git hooks"
    fi
    echo ""
fi

# Install Ruby dependencies if Bundler is available
if command -v bundle &> /dev/null; then
    echo "📦 Installing Ruby dependencies..."
    read -p "Run 'bundle install' now? (Y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        bundle install
        echo -e "${GREEN}✓${NC} Ruby dependencies installed"
    else
        echo "Skipped. Run 'bundle install' manually later."
    fi
    echo ""
fi

# Setup database if Rails is available
if command -v bundle &> /dev/null && [ -f "bin/rails" ]; then
    echo "🗄️  Setting up database..."
    read -p "Run 'rails db:setup' now? (Y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        bundle exec rails db:setup
        echo -e "${GREEN}✓${NC} Database setup complete"
    else
        echo "Skipped. Run 'rails db:setup' manually later."
    fi
    echo ""
fi

echo "======================="
echo ""
echo -e "${GREEN}✅ Bootstrap complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review CONTRIBUTING.adoc for contribution guidelines"
echo "  2. Read CLAUDE.adoc for AI assistant instructions"
echo "  3. Run 'just --list' to see available commands"
echo "  4. Start development server: 'just serve'"
echo ""
echo "For help:"
echo "  • Documentation: cat README.adoc"
echo "  • Task runner: just --list"
echo "  • Rails commands: bin/rails --help"
echo ""
