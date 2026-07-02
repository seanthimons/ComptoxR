---
phase: 37
slug: build-patch-integration
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 37 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3 / devtools |
| **Config file** | `DESCRIPTION`, `tests/testthat/setup.R` |
| **Quick run command** | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` |
| **Full suite command** | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` |
| **Estimated runtime** | ~30-90 seconds |

## Sampling Rate

- **After every task commit:** Run `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` when package code or tests change.
- **After every plan wave:** Run the full targeted lifestage gate test command.
- **Before `$gsd-verify-work`:** Targeted lifestage gate tests and section 16 identity check must be green.
- **Max feedback latency:** 90 seconds for targeted checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | INTG-01/02/03/04 | T-37-01/T-37-02 | Regression tests fail before unsafe patch/build drift ships | unit | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | complete |
| 37-01-02 | 01 | 1 | INTG-03 | T-37-01 | Write-open retry closes stale handles before each connect attempt | unit | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | complete |
| 37-01-03 | 01 | 1 | INTG-02 | T-37-03 | Deterministic local refresh modes do not call live providers unexpectedly | unit | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | complete |
| 37-01-04 | 01 | 1 | INTG-04 | T-37-02 | Patch metadata records complete latest patch state without duplicate stale keys | unit | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | complete |
| 37-01-05 | 01 | 1 | INTG-01 | T-37-04 | Build scripts remain character-identical in section 16 | unit | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | complete |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-28
