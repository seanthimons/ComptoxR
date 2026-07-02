---
phase: 39
slug: quality-gates
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
---

# Phase 39 - Validation Strategy

> Per-phase validation contract for mocked provider adapter quality gates.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat via devtools |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` |
| **Full suite command** | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` |
| **Estimated runtime** | ~60-180 seconds |

## Sampling Rate

- **After every task commit:** Run the quick command when implementation or tests change.
- **After every plan wave:** Run the full suite command.
- **Before `$gsd-verify-work`:** Full suite command must be green.
- **Max feedback latency:** 180 seconds for targeted tests.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | QUAL-01 | T-39-01/T-39-02 | Direct provider tests fail on unexpected live request execution | regression | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | pending |
| 39-01-02 | 01 | 1 | QUAL-01 | T-39-01/T-39-03 | NVS empty and failure paths return the candidate schema without false live calls | unit | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | pending |
| 39-01-03 | 01 | 1 | QUAL-01 | T-39-01/T-39-02 | Existing live/force patch tests keep all provider calls mocked | regression | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | pending |
| 39-01-04 | 01 | 1 | QUAL-01 | all | Final focused quality gate is green and docs/script churn is absent | integration | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `tests/testthat/test-eco_lifestage_gate.R` already contains lifestage gate helpers and testthat style.
- `R/eco_lifestage_patch.R` already contains the provider adapters under test.
- `devtools::test(filter='eco_lifestage_gate')` is already the focused package gate.

## Manual-Only Verifications

All phase behaviors have automated verification. Human review is limited to confirming the final diff does not introduce `NEWS.md`, `dev/lifestage/validate_39.R`, VCR cassettes, or external provider fixture files.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
