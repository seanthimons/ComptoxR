---
phase: 27
slug: test-infrastructure-stabilization
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-09
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x with VCR cassettes |
| **Config file** | tests/testthat.R, tests/testthat/helper-vcr.R |
| **Quick run command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::test(filter='pipeline')"` |
| **Full suite command** | `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe" -e "devtools::test()"` |
| **Estimated runtime** | ~60 seconds (with cassettes) |

---

## Sampling Rate

- **After every task commit:** Run quick run command (pipeline tests)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green (infrastructure-level — assertion failures from migration are expected)
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | NAMESPACE cleanup | unit | `Rscript -e "devtools::check()"` | ✅ | ⬜ pending |
| 27-02-01 | 02 | 1 | VCR sanitization | unit | `Rscript -e "devtools::test(filter='vcr')"` | ✅ | ⬜ pending |
| 27-03-01 | 03 | 2 | Cassette re-recording | integration | `Rscript dev/check_cassette_health.R` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `dev/check_cassette_health.R` — health check script for cassette validation
- [ ] Existing test infrastructure covers NAMESPACE and VCR verification via devtools::check() and devtools::test()

*Existing infrastructure covers most phase requirements; only health check script is new.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cassette re-recording | Full 717 cassette recording | Requires live API key + network access | Run `Rscript dev/record_cassettes.R` with valid ctx_api_key |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
