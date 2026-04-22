---
phase: 34
slug: teardown
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x |
| **Config file** | `tests/testthat.R` (standard devtools layout) |
| **Quick run command** | `devtools::test(filter = "eco_lifestage_gate")` |
| **Full suite command** | `devtools::test()` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `devtools::test(filter = "eco_lifestage_gate")`
- **After every plan wave:** Run `devtools::test()`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | TEAR-01 | — | N/A | verification | `grep -rn "classify_lifestage_keywords" R/ inst/ data-raw/` (exit 1 = pass) | N/A — grep task | ⬜ pending |
| 34-01-02 | 01 | 1 | TEAR-02 | — | N/A | verification | `grep -rn "ontology_id" R/ inst/ data-raw/` (exit 1 = pass) | N/A — grep task | ⬜ pending |
| 34-01-03 | 01 | 1 | TEAR-03 | — | N/A | smoke test | `Rscript dev/lifestage/purge_and_rebuild.R` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `dev/lifestage/purge_and_rebuild.R` — TEAR-03 purge-and-rebuild script (created in Wave 1)

*TEAR-01 and TEAR-02 verification is in-plan grep tasks, not persistent test files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
