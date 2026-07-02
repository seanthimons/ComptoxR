---
phase: 36
slug: bootstrap-data-artifacts
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `testthat::test_file("tests/testthat/test-eco_lifestage_data.R")` |
| **Full suite command** | `devtools::test()` |
| **Estimated runtime** | ~5 seconds (cross-check gate is pure CSV reads) |

---

## Sampling Rate

- **After every task commit:** Run `testthat::test_file("tests/testthat/test-eco_lifestage_data.R")`
- **After every plan wave:** Run `devtools::test()`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | DATA-01 | — | N/A | data | CSV row count + column check | ✅ | ⬜ pending |
| 36-01-02 | 01 | 1 | DATA-02 | — | N/A | data | Derivation CSV column + row check | ✅ | ⬜ pending |
| 36-01-03 | 01 | 1 | DATA-03 | — | N/A | integration | Cross-check anti-join zero gaps | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-eco_lifestage_data.R` — permanent cross-check gate (D-09)
- [ ] Verify existing test infrastructure (`tests/testthat.R`, `testthat` dependency) is in place

*Existing infrastructure covers framework requirements. Only the new test file is needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PO:0000055 / PO:0009010 curator sign-off | DATA-02 | Requires human judgment on harmonized category mapping | Review derivation rows for bud→Adult and seed→Egg/Embryo assignments |
| DB completeness anti-join | DATA-01 | Requires local ecotox.duckdb | Run `dev/lifestage/validate_36.R` with DB present |
| Release match gate | DATA-01 | Requires local ecotox.duckdb | Run validate_36.R; confirm release metadata matches baseline |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
