# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-26)

**Core value:** Generated API wrapper functions must send requests in the format the API expects — correct body encoding, content types, and parameter handling.
**Current focus:** v2.1 Test Infrastructure — Phase 23 (Build Fixes & Test Generator Core)

## Current Position

Phase: 23 of 26 (Build Fixes & Test Generator Core)
Plan: 1 of TBD
Status: Executing
Last activity: 2026-02-27 — Completed 23-01: Build infrastructure fixes

Progress: [█░░░░░░░░░] ~10% (1/TBD plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 9 (4 from v1.9 + 4 from v2.0 + 1 from v2.1)
- Average duration: 3.5 minutes
- Total execution time: 0.47 hours

**Phase 23 metrics:**
| Plan | Duration | Tasks | Files | Date |
|------|----------|-------|-------|------|
| 01   | 5.3 min  | 3     | 7     | 2026-02-27 |

**Recent context:**
- v2.0 phases 19-21 completed in 4 plans
- Phase 22 pagination testing folded into v2.1 milestone
- v2.1 starts fresh with build fixes before any new feature work

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v2.1]: Include build fixes in test infrastructure milestone (entangled with test failures)
- [v2.1]: Nuke all bad VCR cassettes and re-record from production with correct params
- [v2.1]: Both local dev script + CI workflow for test automation
- [v2.1]: Phase 22 pagination testing folded into Phase 26 of this milestone
- [v2.1]: Test generator must read actual tidy flag from function bodies, not assume
- [v2.1]: Test generator must map parameter names to correct test value types

### Known Issues (from TODO)

**Build errors blocking R CMD check:**
- ~~Non-ASCII characters in `R/extract_mol_formula.R`~~ ✅ FIXED (23-01)
- ~~httr2 compatibility issues (resp_is_transient, resp_status_class)~~ ✅ FIXED (23-01)
- ~~License placeholder in DESCRIPTION~~ ✅ FIXED (23-01)
- ~~Unused imports (ggplot2, janitor)~~ ✅ FIXED (23-01)
- ~~Partial argument match (body → body_type)~~ ✅ FIXED (23-01)
- `"RF" <- model = "RF"` invalid syntax in `chemi_arn_cats_bulk`
- Duplicate `endpoint` argument in multiple functions
- Roxygen @param documentation mismatches

**Test failures (834+):**
- 122 stubs use tidy=FALSE but tests assert tibble
- Test generator blindly passes DTXSIDs to all parameters
- 673 untracked VCR cassettes recorded with wrong params

**Root cause:** Test generator doesn't read actual function metadata

### Pending Todos

**Deferred to future milestones:**
- ADV-01-04: Advanced schema handling (content-type extraction, primitive types, nested arrays)
- S7 class implementation (#29)
- Schema-check workflow improvements (#96)
- Advanced testing features (snapshot tests, performance benchmarks, contract testing)

### Blockers/Concerns

None yet. Starting fresh with Phase 23.

## Session Continuity

Last session: 2026-02-27
Stopped at: Completed Phase 23 Plan 01 (Build infrastructure fixes)
Resume file: .planning/phases/23-build-fixes-test-generator-core/23-01-SUMMARY.md

**Archived Milestones:**
- v1.0-v1.9: See `.planning/milestones/` directory
- v2.0: Phases 19-21 complete, Phase 22 folded into v2.1 Phase 26

**Next action:** Continue Phase 23 Plan 02 (Fix generator pipeline core)

---
*Last updated: 2026-02-27 after completing 23-01*
