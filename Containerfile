# Containerfile for Candy Crash LMS
# SPDX-License-Identifier: GPL-3.0-or-later
#
# RSR Compliance:
# - Uses Chainguard Wolfi base (minimal attack surface)
# - Podman-compatible (no Docker daemon required)
# - Rootless execution (non-root user)
# - Minimal dependencies
#
# Build: podman build -t candy-crash -f Containerfile .
# Run:   podman run -p 3000:3000 candy-crash

# Stage 1: Builder (Chainguard Wolfi with build tools)
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

# SPDX-License-Identifier: GPL-3.0-or-later

# Install build dependencies
RUN apk add --no-cache \
    ruby-3.3 \
    ruby-3.3-dev \
    build-base \
    git \
    nodejs \
    yarn \
    sqlite-dev \
    postgresql-dev \
    imagemagick \
    libvips \
    tzdata

# Create app directory
WORKDIR /app

# Copy dependency manifests
COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock* ./

# Install Ruby gems (frozen for security)
RUN gem install bundler -v '~> 2.5' && \
    bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Install JavaScript dependencies
RUN yarn install --frozen-lockfile --production

# Copy application code
COPY . .

# Precompile assets
ENV RAILS_ENV=production \
    RACK_ENV=production \
    SECRET_KEY_BASE=placeholder_for_asset_compilation \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1

RUN bundle exec rails assets:precompile

# Compile bootsnap cache
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Stage 2: Runtime (Minimal Chainguard Wolfi)
FROM cgr.dev/chainguard/wolfi-base:latest

# SPDX-License-Identifier: GPL-3.0-or-later

# Install only runtime dependencies (no build tools)
RUN apk add --no-cache \
    ruby-3.3 \
    nodejs \
    sqlite-libs \
    postgresql-client \
    imagemagick \
    libvips \
    tzdata \
    ca-certificates

# Create non-root user (RSR security requirement)
RUN addgroup -g 1000 rails && \
    adduser -D -u 1000 -G rails rails

# Set working directory
WORKDIR /app

# Copy dependencies from builder
COPY --from=builder --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=rails:rails /app /app

# Create necessary directories with correct permissions
RUN mkdir -p /app/tmp /app/log /app/public/uploads /app/storage && \
    chown -R rails:rails /app

# Switch to non-root user
USER rails

# Environment variables
ENV RAILS_ENV=production \
    RACK_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    PORT=3000 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD ruby -e "require 'net/http'; exit(Net::HTTP.get_response(URI('http://localhost:3000/up')).code.to_i == 200 ? 0 : 1)"

# Security: Drop all capabilities (defense in depth)
# Note: This requires Podman/OCI runtime support
# LABEL security.capabilities.drop=all

# Security labels
LABEL org.opencontainers.image.title="Candy Crash LMS" \
      org.opencontainers.image.description="UK Driving Licence Preparation Platform" \
      org.opencontainers.image.url="https://github.com/Hyperpolymath/candy-crash" \
      org.opencontainers.image.source="https://github.com/Hyperpolymath/candy-crash" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.vendor="Hyperpolymath" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.base.name="cgr.dev/chainguard/wolfi-base:latest" \
      com.candy-crash.rsr-compliance="Gold" \
      com.candy-crash.security.user="rails:rails" \
      com.candy-crash.security.rootless="true"

# Start application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
