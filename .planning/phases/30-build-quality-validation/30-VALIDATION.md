---
phase: 30
slug: build-quality-validation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x + vcr (R package testing) |
| **Config file** | tests/testthat.R, tests/testthat/helper-vcr.R |
| **Quick run command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::test()"` |
| **Full suite command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::check()"` |
| **Estimated runtime** | ~120 seconds (check), ~30 seconds (test) |

---

## Sampling Rate

- **After every task commit:** Run `devtools::test()` for affected areas
- **After every plan wave:** Run `devtools::check()` — verify 0 errors
- **Before `/gsd:verify-work`:** Full `devtools::check()` must show 0 errors
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | YAML-DEP | integration | `devtools::check()` — verify yaml loads | ✅ existing hook tests | ⬜ pending |
| 30-01-02 | 01 | 1 | DUP-ARG | unit | `devtools::check()` — verify no formal arg error | ✅ existing stub tests | ⬜ pending |
| 30-01-03 | 01 | 1 | BUILD-CLEAN | integration | `devtools::check()` — 0 errors | ✅ R CMD check | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* Test framework (testthat + vcr) and R CMD check tooling already in place.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| R CMD check 0 errors | BUILD-CLEAN | User runs final check | Run `devtools::check()`, confirm 0 errors in output |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
