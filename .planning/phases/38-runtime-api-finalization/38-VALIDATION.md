---
phase: 38
slug: runtime-api-finalization
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 38 - Validation Strategy

> Per-phase validation contract for runtime ECOTOX lifestage API finalization.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat via devtools |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` |
| **Full suite command** | `Rscript -e "devtools::test(filter='eco_(functions|lifestage_gate)')"` |
| **Estimated runtime** | ~60-180 seconds |

## Sampling Rate

- **After every task commit:** Run the quick command when implementation or tests change.
- **After every plan wave:** Run the full suite command.
- **Before `$gsd-verify-work`:** Full suite command plus `Rscript -e "devtools::document()"` must complete.
- **Max feedback latency:** 180 seconds for targeted tests.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 38-01-01 | 01 | 1 | RUNT-01/RUNT-02/RUNT-03 | T-38-01/T-38-02/T-38-03 | Runtime output contract is test-locked before implementation | regression | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | pending |
| 38-01-02 | 01 | 1 | RUNT-01/RUNT-02/RUNT-03 | T-38-01/T-38-02/T-38-03 | Local DuckDB route applies compact/detail selection and aborts on stale schema | unit/integration | `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` | yes | pending |
| 38-01-03 | 01 | 1 | RUNT-01/RUNT-02 | T-38-02 | Plumber route uses same selector and docs match public API | unit/docs | `Rscript -e "devtools::document(); devtools::test(filter='eco_(functions|lifestage_gate)')"` | yes | pending |
| 38-01-04 | 01 | 1 | RUNT-01/RUNT-02/RUNT-03 | all | Final targeted phase checks are green | integration | `Rscript -e "devtools::test(filter='eco_(functions|lifestage_gate)')"` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `tests/testthat/test-eco_lifestage_gate.R` has temporary DuckDB fixtures for patched runtime reads.
- `tests/testthat/test-eco_functions.R` has existing `eco_results()` behavior coverage.
- `R/eco_functions.R` already contains the local and Plumber runtime routes.

## Manual-Only Verifications

All phase behaviors have automated verification. Human review is limited to checking generated documentation diffs for clarity after `devtools::document()`.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution

