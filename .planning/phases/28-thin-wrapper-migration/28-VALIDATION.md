---
phase: 28
slug: thin-wrapper-migration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x with VCR cassettes |
| **Config file** | tests/testthat.R, tests/testthat/helper-vcr.R |
| **Quick run command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::test(filter='hook')"` |
| **Full suite command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::test()"` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command (hook tests)
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 0 | Hook registry | unit | `devtools::test(filter='hook_registry')` | ❌ W0 | ⬜ pending |
| 28-01-02 | 01 | 0 | Hook config YAML | unit | `devtools::test(filter='hook_config')` | ❌ W0 | ⬜ pending |
| 28-02-01 | 02 | 1 | Pass-through deletion | integration | `devtools::test(filter='ct_hazard')` | ✅ | ⬜ pending |
| 28-03-01 | 03 | 2 | Pre/post hooks | unit | `devtools::test(filter='hook')` | ❌ W0 | ⬜ pending |
| 28-04-01 | 04 | 3 | Complex hooks | unit+integration | `devtools::test()` | ✅ | ⬜ pending |
| 28-05-01 | 05 | 4 | CI drift check | script | `Rscript dev/check_hook_config.R` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-hook_registry.R` — unit tests for hook registry
- [ ] `tests/testthat/test-hook_config.R` — YAML config parsing tests
- [ ] `R/hook_registry.R` — hook registry implementation
- [ ] `inst/hook_config.yml` — hook configuration file

*Existing test infrastructure (testthat, VCR) covers integration testing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| IDE autocomplete for hook params | UX quality | IDE-specific | Open RStudio, type `ct_hazard_toxval_search_bulk(` and verify extra_params appear |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
