<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
-->

# Changelog

All notable changes to `candy-crash` will be documented in this file.

This file is generated from conventional commits by the
[`changelog-reusable.yml`](https://github.com/hyperpolymath/standards/blob/main/.github/workflows/changelog-reusable.yml)
workflow (`hyperpolymath/standards#206`). Adopt the workflow in this repo's CI to keep this file in sync automatically — see
[`templates/cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml)
for the canonical config.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- feat: add Grade B test suite (6 targets)

### Fixed

- fix(ci): sync hypatia-scan.yml to canonical (413: env.HOME+Phase-2+SARIF) (#31)
- fix(ci): adopt canonical hypatia-scan.yml (env.HOME/scanner-layout + Comment-step gate) (#28)
- fix(ci): Phase-2 fleet submission must not fail the security gate (#27)
- fix(ci): hypatia-scan workdir (${{ env.HOME }} resolves empty) (#26)
- fix(ci): move secret-scanner Cargo.toml gate from job-level if: to step-level (#25)

### Documentation

- docs(readme): add SPDX header, OSSF and GWF badges
- docs: add post-audit status report for M5 sweep
- docs(explainme): add EXPLAINME.adoc

### CI

- ci(secret-scanner): drop duplicate --fail from trufflehog extra_args (#24)
- ci: bump actions/upload-artifact SHA to current v4 (#23)
- ci: fix workflow-linter YAML parse error + self-flag bug
- ci: add 0-AI-MANIFEST.a2ml for RSR compliance

## Pre-history

Prior commits to this file's introduction are recorded in git history but not formally classified into Keep-a-Changelog sections. To backfill, run `git cliff -o CHANGELOG.md` locally using the canonical [`cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml) — this is one-shot mechanical work.

---

<!-- This file was seeded by the 2026-05-26 estate tech-debt audit follow-up (Row-2 Phase 3); see [`hyperpolymath/standards/docs/audits/2026-05-26-estate-documentation-debt.md`](https://github.com/hyperpolymath/standards/blob/main/docs/audits/2026-05-26-estate-documentation-debt.md). -->
