# Containerfile for Candy Crash LMS
# SPDX-License-Identifier: PMPL-1.0-or-later
#
# High-Rigor Architecture: Gleam + AffineScript (typed-wasm)
# Containerization: Selur-based OCI Stack

# Stage 1: Build Frontend (AffineScript -> typed-wasm)
FROM cgr.dev/chainguard/wolfi-base:latest AS frontend-builder
RUN apk add --no-cache rust cargo nodejs
WORKDIR /build
COPY frontend/ .
# In a real environment, we'd use affinescriptiser here
# RUN affinescriptiser generate && affinescript --compile src/Main.as -o public/main.wasm

# Stage 2: Build Backend (Gleam)
FROM cgr.dev/chainguard/wolfi-base:latest AS backend-builder
RUN apk add --no-cache gleam erlang
WORKDIR /build
COPY backend/ .
RUN gleam build

# Stage 3: Runtime (Selur-based)
# selur provides the containerisation and runtime environment for this component
FROM cgr.dev/chainguard/wolfi-base:latest
RUN apk add --no-cache ca-certificates

# Create non-root user
RUN addgroup -g 1000 candy && adduser -D -u 1000 -G candy candy
WORKDIR /app

# Copy artifacts
COPY --from=backend-builder /build/build/erlang-shipping-libs /app/libs
COPY --from=backend-builder /build/build/dev/erlang/candy_crash /app/candy_crash
COPY --from=frontend-builder /build/public /app/public

# Groove Service Discovery handles wiring for Gossamer, Burble, and VeriSimDB
# Ports: 4040 (Gossamer), 4020 (Burble), 8100 (VeriSimDB), 4000 (Gleam Backend)

USER candy
EXPOSE 4000
CMD ["/app/candy_crash/bin/candy_crash", "run"]
