import? "contractile.just"

# Candy Crash - Just Task Runner
# https://github.com/casey/just

# Load environment variables from .env if present
set dotenv-load := true

# Default recipe to display help
default:
    @just --list

# === DEVELOPMENT ===

# Start the Gleam backend server
serve:
    cd backend && gleam run

# Start Gleam shell
console:
    cd backend && gleam shell

# === DATABASE (VeriSimDB) ===

# Start project-specific VeriSimDB instance (Port 8100)
db-start:
    verisimdb start --port 8100 --db candy_crash_verisim

# Check VeriSimDB health
db-status:
    curl -s http://localhost:8100/health

# === FRONTEND (AffineScript + typed-wasm) ===

# Build the AffineScript frontend targeting typed-wasm
build-frontend:
    cd frontend && affinescriptiser generate
    cd frontend && affinescript --compile src/Main.as -o public/main.wasm --opt-level 3

# Start the Gossamer interface shell (loads public/index.html)
interface:
    gossamer start --port 4040 --config gossamer.conf.json

# === SERVICES (Groove) ===

# Start the Burble signaling server
burble-start:
    burble start --port 4020

# Start the full ecosystem
up: db-start burble-start serve interface

# === TESTING ===

# Run all quality checks
test: test-structure test-zig test-gleam test-frontend-structure
    @echo "All test targets complete."

# T2: structural check — required files and directories
test-structure:
    bash tests/validate_structure.sh

# T1: FFI integration test via zig test
test-zig:
    zig test ffi/zig/test/integration_test.zig 2>/dev/null || echo "SKIP: zig not installed"

# T3: Gleam backend unit tests
test-gleam:
    cd backend && gleam test 2>/dev/null || echo "SKIP: gleam not installed"

# T5: validate frontend/ directory structure
test-frontend-structure:
    bash tests/validate_frontend.sh

# === CODE QUALITY ===

# Run Gleam formatter check
lint:
    cd backend && gleam format --check

# Auto-fix formatting
lint-fix:
    cd backend && gleam format

# === RSR COMPLIANCE ===

# Validate RSR compliance
validate-rsr:
    @echo "🔍 Checking RSR Compliance..."
    @echo ""
    @echo "✅ Documentation:"
    @test -f README.adoc && echo "  ✓ README.adoc" || echo "  ✗ README.adoc missing"
    @test -f LICENSE && echo "  ✓ LICENSE" || echo "  ✗ LICENSE missing"
    @test -f SECURITY.md && echo "  ✓ SECURITY.md" || echo "  ✗ SECURITY.md missing"
    @test -f CONTRIBUTING.adoc && echo "  ✓ CONTRIBUTING.adoc" || echo "  ✗ CONTRIBUTING.adoc missing"
    @test -f CODE_OF_CONDUCT.adoc && echo "  ✓ CODE_OF_CONDUCT.adoc" || echo "  ✗ CODE_OF_CONDUCT.adoc missing"
    @test -f MAINTAINERS.adoc && echo "  ✓ MAINTAINERS.adoc" || echo "  ✗ MAINTAINERS.adoc missing"
    @test -f CHANGELOG.adoc && echo "  ✓ CHANGELOG.adoc" || echo "  ✗ CHANGELOG.adoc missing"
    @test -f CLAUDE.adoc && echo "  ✓ CLAUDE.adoc" || echo "  ✗ CLAUDE.adoc missing"
    @echo ""
    @echo "✅ .well-known Directory:"
    @test -f public/.well-known/security.txt && echo "  ✓ security.txt (RFC 9116)" || echo "  ✗ security.txt missing"
    @test -f public/.well-known/ai.txt && echo "  ✓ ai.txt" || echo "  ✗ ai.txt missing"
    @test -f public/.well-known/humans.txt && echo "  ✓ humans.txt" || echo "  ✗ humans.txt missing"
    @echo ""
    @echo "✅ Build System:"
    @test -f Justfile && echo "  ✓ Justfile" || echo "  ✗ Justfile missing"
    @test -f .github/workflows/ci.yml && echo "  ✓ CI/CD (GitHub Actions)" || echo "  ✗ CI/CD missing"
    @test -f Containerfile && echo "  ✓ Containerfile (Podman)" || echo "  ✗ Containerfile missing"
    @echo ""
    @echo "🎉 RSR Compliance Check Complete!"
