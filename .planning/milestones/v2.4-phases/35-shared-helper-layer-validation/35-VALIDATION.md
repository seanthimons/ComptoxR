---
phase: 35
slug: shared-helper-layer-validation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x |
| **Config file** | tests/testthat.R |
| **Quick run command** | `testthat::test_file("tests/testthat/test-eco_lifestage_gate.R")` |
| **Full suite command** | `devtools::test()` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `testthat::test_file("tests/testthat/test-eco_lifestage_gate.R")`
- **After every plan wave:** Run `devtools::test()`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | PROV-01 | — | N/A | integration | `devtools::load_all()` | ✅ | ⬜ pending |
| 35-01-02 | 01 | 1 | PROV-02 | — | OLS4 prefix filter | unit | `testthat::test_file("tests/testthat/test-eco_lifestage_gate.R")` | ✅ | ⬜ pending |
| 35-01-03 | 01 | 1 | PROV-03 | — | NVS graceful failure | unit | `testthat::test_file("tests/testthat/test-eco_lifestage_gate.R")` | ✅ | ⬜ pending |
| 35-01-04 | 01 | 1 | PROV-04 | — | BioPortal fallback only | manual | N/A (deferred) | ❌ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-eco_lifestage_gate.R` — add NVS failure test case (cli_warn + empty tibble)
- [ ] `dev/lifestage/validate_35.R` — dev validation script for adapter shape checks

*Existing test infrastructure covers most phase requirements; Wave 0 adds NVS failure coverage.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| BioPortal fallback-only | PROV-04 | BioPortal adapter deferred to later phase | Verify by reading `.eco_lifestage_resolve_term()` — confirm BioPortal is never called as first-pass |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
