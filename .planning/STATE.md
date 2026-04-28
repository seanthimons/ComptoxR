---
gsd_state_version: 1.0
milestone: v2.4
milestone_name: Source-Backed Lifestage Resolution
status: planning
last_updated: "2026-04-28T17:58:00-04:00"
last_activity: 2026-04-28
progress:
  total_phases: 11
  completed_phases: 7
  total_plans: 11
  completed_plans: 11
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-22)

**Core value:** Researchers can query EPA CompTox APIs through stable, well-tested R functions that handle authentication, batching, pagination, and result formatting automatically.
**Current focus:** Phase 39 - Quality Gates

## Current Position

Phase: 39 (Quality Gates) - READY TO PLAN
Plan: pending
Status: Phase 38 verified complete; Phase 39 quality gates are next
Last activity: 2026-04-28

```
Progress: [====================] 100% (1/1 plans)
```

## Performance Metrics

- Phases complete: 6/6
- Plans complete: 1/1 for Phase 38

## Accumulated Context

### Decisions

- v2.3 regex-first lifestage approach was wrong — cosmetic provenance, not source-backed
- v2.4 tears out v2.3 implementation entirely and replaces with ontology API resolution
- Existing lifestage tables purged from DB; rebuilt on-demand
- Target 7 harmonized categories but final set adjusts based on OLS4/NVS API results
- Minimal test coverage — no full test suite needed
- `R/eco_lifestage_patch.R` (926 lines, 14 functions) already exists on disk — this milestone is validation and wiring, not new code
- Both build scripts already have section 16 replacements; both data CSVs already exist in inst/extdata/ecotox/
- BioPortal is a FALLBACK provider only — invoked when OLS4 returns unresolved or ambiguous
- DuckDB Windows write-connection retry: 3 attempts / 200 ms back-off
- OLS4 cross-ontology fix: post-filter by obo_id prefix (UBERON: or PO:) after each query
- No new DESCRIPTION dependencies needed — all packages already in Imports

- Phase 36.2 added a source-backed semantic adjudication artifact preserving `org_lifestage + eco_group + kingdom + class_name` context
- `needs_context_aware_derivation` rows are intentional non-blocking review handoff rows; validation warns but does not fail on them
- Phase 37 made `force = TRUE` the explicit live-provider patch route; ordinary `auto` and local seed paths remain deterministic and do not silently call live providers.
- Phase 37 added a patch write-open retry boundary: 3 close/connect attempts with 200 ms back-off before a patch-specific read-write-open error.
- Phase 38 finalized `eco_results()` lifestage runtime output: compact by default, detailed provenance via `lifestage_details = TRUE`, and no `ontology_id` output.
- Phase 38 added a stale lifestage runtime schema guard that points users to patch or rebuild the ECOTOX DB.

### Pending Todos

- Plan Phase 39 Quality Gates

### Roadmap Evolution

- Phase 36.1 inserted after Phase 36: Unresolved Coverage Audit (URGENT)
- Phase 36.2 inserted after Phase 36.1: Dictionary Rebuild Validation (URGENT)

### Blockers/Concerns

None.

## Archived Milestones

- v1.0-v1.9: Phases 1-18 (shipped 2026-01-27 to 2026-02-12)
- v2.0: Phases 19-21 (paginated requests) - shipped 2026-02-24
- v2.1: Phases 23-26 (test infrastructure) - shipped 2026-03-02
- v2.2: Phases 27-30 (package stabilization) - shipped 2026-03-11
- v2.3: Phases 31-33 (ECOTOX lifestage harmonization) - shipped 2026-04-21

Full history: `.planning/MILESTONES.md`

---
*Last updated: 2026-04-22 — Roadmap created for v2.4 (Phases 34-39)*
