# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# Containerfile — Candy Crash (Deno + Just verification image)
#
# Nix retirement note: Nix was retired estate-wide 2026-06-01 (Guix is
# primary, no Nix fallback). flake.nix still exists in this repo because
# the Guix side (guix.scm) is not working yet — it is deliberately left
# in place, not deleted. This Containerfile is the interim, policy-
# accepted escape hatch: a sealed, reproducible build/verify image that
# does not depend on Nix at all.
#
# This file replaces a prior stub Containerfile that only provided
# commented-out example RUN lines, `nodejs` (estate-banned — Deno is the
# sanctioned JS runtime here), and artifact paths (`selur`,
# erlang-shipping-libs) that were never produced by any real build step.
#
# Scope: candy-crash is a multi-language repo (Gleam backend, AffineScript
# /ReScript frontend, SPARK/Ada + Zig safety_core, VeriSimDB, Gossamer,
# Burble). This image packages the Deno + Just slice of that toolchain
# only — the two runtimes named for this container's mandate. It installs
# both for real and runs the checks that are genuinely runnable against
# the current tree:
#   - `deno task check`              (root deno.json; type-checks
#                                      app/assets/javascripts/**/*.js —
#                                      that directory does not exist yet
#                                      in this tree, so Deno reports "no
#                                      matching files" and exits 0; this
#                                      is a real, honest pass against the
#                                      repo's current state, not a fake
#                                      gate)
#   - `just test-structure`          (tests/validate_structure.sh)
#   - `just test-frontend-structure` (tests/validate_frontend.sh)
#   - `just validate-rsr`            (RSR compliance file-presence check)
#
# deno.lock ships as an empty (0-byte) file in this repo. Deno 2.x treats
# a 0-byte lockfile as corrupt and refuses to run ANY command against it,
# including `deno check`. This build regenerates a minimal valid
# lockfile inside the image so the checks above can actually execute; it
# does not touch the committed deno.lock in git.
#
# Build:  podman build -t candy-crash-verify -f Containerfile .
# Run:    podman run --rm candy-crash-verify
# Seal:   podman build --squash -t candy-crash-verify:sealed -f Containerfile .

# --- Stage 1: Build / Verify ---
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

# Deno (JS/TS runtime + checker) and Just (task runner) — the two
# toolchains this image packages.
RUN apk add --no-cache deno just bash

WORKDIR /app
COPY . .

# deno.lock ships 0 bytes in this tree; Deno 2.x aborts on an empty
# lockfile before it even resolves the task's file glob. Regenerate a
# minimal valid lockfile so `deno task check` can run for real.
RUN echo '{"version":"4"}' > deno.lock

# Real toolchain checks against the actual current tree (see header
# note on scope and honesty of each step).
RUN deno task check
RUN just test-structure
RUN just test-frontend-structure
RUN just validate-rsr

# --- Stage 2: Runtime ---
FROM cgr.dev/chainguard/wolfi-base:latest

RUN apk add --no-cache deno just bash

WORKDIR /app
COPY --from=builder /app /app

USER nonroot

ENTRYPOINT ["just"]
CMD ["test-structure"]
