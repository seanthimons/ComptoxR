---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
stopped_at: Completed 30-01-PLAN.md
last_updated: "2026-03-11T20:00:30.831Z"
last_activity: 2026-03-11 — Completed 29-01 (property search migration) and 29-02 (ct_related migration)
progress:
  total_phases: 29
  completed_phases: 28
  total_plans: 56
  completed_plans: 55
---

---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
stopped_at: Completed 29-02-PLAN.md
last_updated: "2026-03-11T16:10:31Z"
last_activity: 2026-03-11 — Completed 29-02 (ct_related migration to generic_request)
progress:
  total_phases: 29
  completed_phases: 27
  total_plans: 53
  completed_plans: 54
  percent: 100
---

---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
stopped_at: Completed 28-05-PLAN.md
last_updated: "2026-03-11T15:08:53.531Z"
last_activity: 2026-03-11 — Completed 28-04 (generator hook integration and wrapper cleanup)
progress:
  total_phases: 29
  completed_phases: 26
  total_plans: 53
  completed_plans: 52
  percent: 98
---

---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
stopped_at: Completed 28-04-PLAN.md
last_updated: "2026-03-11T14:58:21.086Z"
last_activity: 2026-03-11 — Completed 28-03 (deleted thin wrapper functions)
progress:
  [██████████] 98%
  completed_phases: 25
  total_plans: 53
  completed_plans: 50
  percent: 94
---

---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
stopped_at: Completed 28-03-PLAN.md
last_updated: "2026-03-11T14:48:29.038Z"
last_activity: 2026-03-11 — Completed 28-01 (hook system foundation)
progress:
  [█████████░] 94%
  completed_phases: 25
  total_plans: 53
  completed_plans: 49
  percent: 92
---

---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
stopped_at: Phase 28 context gathered
last_updated: "2026-03-10T20:26:56.874Z"
last_activity: 2026-03-09 — Completed 27-01 (selective purrr/jsonlite imports)
progress:
  [█████████░] 92%
  completed_phases: 25
  total_plans: 48
  completed_plans: 47
  percent: 98
---

---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
last_updated: "2026-03-09T21:06:43.429Z"
last_activity: 2026-03-09 — v2.1 verified, retroactive summaries written, docs realigned
progress:
  [██████████] 98%
  completed_phases: 25
  total_plans: 48
  completed_plans: 46
---

---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: Package Stabilization
status: in_progress
last_updated: "2026-03-09T00:00:00.000Z"
progress:
  total_phases: 30
  completed_phases: 26
  total_plans: 45
  completed_plans: 45
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-09)

**Core value:** Researchers can query EPA CompTox APIs through stable, well-tested R functions that handle authentication, batching, pagination, and result formatting automatically.
**Current focus:** v2.2 Package Stabilization — ready to plan Phase 27

## Current Position

Phase: 29 (Direct Template Migration) — COMPLETE
Plan: Both plans complete (2/2 plans executed)
Status: Phase 29 complete, ready for Phase 30
Last activity: 2026-03-11 — Completed 29-01 (property search migration) and 29-02 (ct_related migration)

Progress: [██████████] 100% (54/53 plans executed — Phase 29 added 1 plan)

## Milestone v2.2 Overview

**Goal:** Migrate all user-facing ct_* functions to use generated stubs via generic_request(), classify functions by complexity, and get the package to a clean build + passing test state.

**Phases:**
- Phase 27: Test Infrastructure Stabilization (in progress — 1/3 plans complete)
- Phase 28: Thin Wrapper Migration (not yet planned)
- Phase 29: Direct Template Migration (not yet planned)
- Phase 30: Build Quality Validation (not yet planned)

**Total:** 4 phases, 3 plans in progress, 1 complete

## Archived Milestones

- v1.0-v1.9: See `.planning/milestones/` directory
- v2.0: Phases 19-21 (paginated requests) — shipped 2026-02-24
- v2.1: Phases 23-26 (test infrastructure) — shipped 2026-03-02, verified 2026-03-09

Full history: `.planning/MILESTONES.md`

## Accumulated Context

**From v2.1:**
- 297 pre-existing test failures from VCR/API key issues (not caused by v2.1)
- Only 33 of 256 API wrappers have recorded cassettes
- Re-recording script built but not executed (requires API key)

**From Phase 27-01 (2026-03-09):**
- purrr::flatten deprecation warning FIXED — migrated to selective @importFrom
- Package now loads cleanly without warnings
- 11 purrr functions imported selectively: map, map2, map_chr, map_lgl, imap, pluck, set_names, compact, keep, list_rbind, list_flatten
- 3 jsonlite functions imported selectively: fromJSON, flatten, write_json

**From debate analysis (2026-03-04):**
- Approved approach: Modified B+C hybrid (fix blockers -> classify functions -> migrate thin -> vertical-slice complex -> defer infrastructure)
- Key insight: "circular dependency" between migration/infrastructure/tests is largely illusory — real blockers are mechanical bugs
- Post-processing recipe system (#120) deferred — current stable functions are thin wrappers, pattern proven by ct_lists_all
- Functions classified as: thin (ct_hazard, ct_functional_use), medium (ct_details, ct_env_fate), complex (ct_bioactivity, ct_lists_all)

**From roadmap creation (2026-03-04):**
- 4 phases derived from 18 requirements (standard depth)
- Test infrastructure fixes first (Phase 27) — enables confident migration
- Simple patterns first (Phase 28-29) — thin wrappers, direct templates
- Complex function validation deferred to final phase (Phase 30) — ct_bioactivity, ct_lists_all
- 100% requirement coverage validated

**From doc realignment (2026-03-09):**
- ROADMAP.md, STATE.md, PROJECT.md corrected to match disk state
- v2.1 un-shipped: Phases 23 and 25 have unexecuted plans
- v2.2 phase directories created (27-30), entries added to roadmap
- Prior health check had prematurely marked v2.1 as complete

**From Phase 28-01 (2026-03-11):**
- Hook system foundation complete — .HookRegistry environment and run_hook() dispatcher
- YAML-based hook configuration in inst/hook_config.yml (9 function entries)
- 11 test assertions passing for registry loading, hook dispatch, and error handling
- load_hook_config() integrated into .onLoad — hooks available at package load time
- Supports pre_request, post_response, and transform hook types
- No-op behavior when hooks missing enables gradual migration

**From Phase 28-03 (2026-03-11):**
- Deleted 8 pure pass-through wrapper functions: ct_hazard, ct_cancer, ct_env_fate, ct_demographic_exposure, ct_general_exposure, ct_functional_use, ct_functional_use_probability, ct_genotox
- Deleted deprecated ct_descriptors (INDIGO endpoint not in published schemas)
- Deleted empty ct_synonym.R file
- All delegation targets verified to exist before deletion
- Generated stub names now exposed as public API (clean break, no deprecation shim)
- NEWS.md documents breaking changes with explicit migration guide
- Package builds and loads cleanly after deletions

**From Phase 28-04 (2026-03-11):**
- Extended stub generator with hook parameter injection and call generation
  - Reads inst/hook_config.yml at generation time
  - Injects extra_params into function signatures with defaults and @param docs
  - Inserts run_hook() calls at pre_request and post_response lifecycle points
  - Modified 11 glue templates to support hook calls via template variables
  - Non-hook functions unchanged (has_hooks flag gates modifications)
  - Generator parses without syntax errors
- Created dev/check_hook_config.R CI drift detection script
  - Validates YAML hook function references resolve to real functions
  - Checks declared extra_params exist in generated stub signatures
  - Searches all R files for function definitions (handles multi-function stubs)
  - Fails build if config-param mismatch detected
  - Currently flags 4 bioactivity stubs needing regeneration (expected state)
- Deleted 5 hand-written wrapper functions replaced by hook-powered stubs:
  - ct_lists_all, ct_bioactivity, ct_similar, ct_list, ct_compound_in_list
  - All logic migrated to declarative hooks
  - devtools::document() auto-deleted 5 .Rd files, updated NAMESPACE
  - Package loads cleanly after deletions
- Updated NEWS.md with comprehensive breaking changes and migration paths

**From Phase 28-05 (2026-03-11):**
- Regenerated 4 bioactivity stubs with hook parameters
  - Added annotate = FALSE parameter to ct_bioactivity_data_search_bulk
  - Added annotate = FALSE parameter to ct_bioactivity_data_search_by_aeid_bulk
  - Added annotate = FALSE parameter to ct_bioactivity_data_search_by_spid_bulk
  - Added annotate = FALSE parameter to ct_bioactivity_data_search_by_m4id_bulk
  - All include run_hook() post_response calls for annotate_assay_if_requested hook
  - CI drift check now passes (8 functions, 9 hooks, 4 extra params validated)
- Extended test generator (dev/generate_tests.R) with hook awareness
  - Reads inst/hook_config.yml at generation time
  - For functions with extra_params, generates additional test variants
  - Creates unique cassette names per variant (e.g., {function_name}_{param_name})
  - Handles boolean (test with TRUE), numeric (test with non-default), and other param types
- Updated 4 test files referencing deleted wrapper functions
  - test-ct_bioactivity.R: Now calls ct_bioactivity_data_search_bulk() with annotate param
  - test-ct_lists_all.R: Now calls ct_chemical_list_all() with projection param
  - test-ct_functional_use.R: Now calls ct_exposure_functional_use_search_bulk()
  - test-ct_list.R: Now calls ct_chemical_list_search_by_name() / _bulk()
- Finalized NEWS.md with comprehensive Phase 28 migration guide
  - Simple pass-through wrappers removed section (8 functions)
  - Hook-powered wrappers replaced section (5 functions + examples)
  - New Features section documenting hook system architecture
- Validation results:
  - 42 hook tests passing (11 registry + 31 primitives)
  - Package loads cleanly (devtools::load_all())
  - CI drift check passes (dev/check_hook_config.R)
  - devtools::check() has environmental quarto error (not code-related)
- **Phase 28 complete:** Thin wrapper migration fully operational

**From Phase 29-01 (2026-03-11):**
- Deleted ct_properties() wrapper function
  - Users now call ct_chemical_property_experimental_search_bulk() and ct_chemical_property_predicted_search_bulk() directly
  - Range searches use ct_chemical_property_experimental_search_by_range() with path_params
  - Added coerce hook to split results by propertyId into named list of data frames
- Deleted .prop_ids() internal helper
  - Users call ct_chemical_property_experimental_name() and ct_chemical_property_predicted_name() stubs directly
- Added property_hooks.R with coerce_by_property_id hook primitive
- Updated inst/hook_config.yml with coerce parameter for property search stubs
- Regenerated property search stubs with hook support
- Updated tests to call new stub names
- NEWS.md documents breaking changes and migration paths

**From Phase 29-02 (2026-03-11):**
- Migrated ct_related() from raw httr2 to generic_request template
  - Uses batch_limit=0 pattern for query-string-based GET endpoint
  - Server cleanup guaranteed via on.exit (fixes potential leak on error)
  - Added error handling for empty API responses
  - Manual purrr::map loop for per-DTXSID query parameters
- Added 4 new tests for server cleanup and input validation
- All 7 tests passing
- **Phase 29 complete:** Zero raw httr2 code remaining in package

## Pending Todos

**Deferred pipeline work (ON HOLD):**
- ADV-01-04: Advanced schema handling
- S7 class implementation (#29)
- Schema-check workflow improvements (#96)
- Advanced testing features

**Deferred package work:**
- Post-processing recipe system (#120) — defer until concrete need surfaces

## Session Continuity

Last session: 2026-03-11T20:00:30.824Z
Action: Completed 29-02-PLAN.md — ct_related migration to generic_request
Stopped at: Completed 30-01-PLAN.md
Next: Plan Phase 30 (Build Quality Validation) or verify milestone completion

---
*Last updated: 2026-03-11 after completing Phase 29 Plan 02*
