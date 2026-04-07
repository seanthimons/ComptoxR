---
phase: 29
slug: direct-template-migration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x with vcr cassettes |
| **Config file** | tests/testthat.R, tests/testthat/helper-vcr.R |
| **Quick run command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::test(filter='hook')"` |
| **Full suite command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::test()"` |
| **Estimated runtime** | ~30 seconds (quick), ~120 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run quick hook tests
- **After every plan wave:** Run `devtools::test()` + `devtools::document()`
- **Before `/gsd:verify-work`:** Full suite must be green (excluding pre-existing VCR failures)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | PROP-COERCE | unit | `devtools::test(filter='hook_primitives')` | ✅ | ⬜ pending |
| 29-01-02 | 01 | 1 | PROP-DELETE | build | `devtools::load_all()` | ✅ | ⬜ pending |
| 29-02-01 | 02 | 1 | REL-MIGRATE | unit | `devtools::test(filter='ct_related')` | ❌ W0 | ⬜ pending |
| 29-02-02 | 02 | 1 | REL-VALIDATE | integration | manual head-to-head | N/A | ⬜ pending |
| 29-03-01 | 03 | 2 | NEWS-DOC | build | `devtools::check()` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-ct_related.R` — test stubs for ct_related_EXP migration validation
- [ ] Existing hook test infrastructure covers property coerce hook

*Hook test infrastructure (test-hook_registry.R, test-hook_primitives.R) already exists from Phase 28.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ct_related_EXP head-to-head | REL-VALIDATE | Requires live API key + server 9 access | Call both functions with same DTXSID, compare results |
| Range query stubs work | PROP-RANGE | Requires live API key for first cassette recording | Call ct_chemical_property_experimental_search_by_range with known property + range |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
