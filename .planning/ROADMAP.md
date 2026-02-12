# Roadmap: ComptoxR v1.9 Schema Check Workflow Fix

## Overview

Fix the broken schema-check GitHub Action workflow by resolving the unicode_map dependency issue, then enhance it with endpoint-level diffing and reliability improvements. This milestone delivers a working CI workflow that provides structured feedback on schema changes and handles API failures gracefully.

## Milestones

- ✅ **v1.0 Stub Generation Fix** - Phases 1-2 (shipped 2026-01-27)
- ✅ **v1.1 Raw Text Body Fix** - Phase 3 (shipped 2026-01-27)
- ✅ **v1.2 Bulk Request Body Type Fix** - Phase 4 (shipped 2026-01-28)
- ✅ **v1.3 Chemi Resolver Integration Fix** - Phase 5 (shipped 2026-01-28)
- ✅ **v1.4 Empty POST Endpoint Detection** - Phase 6 (shipped 2026-01-29)
- ✅ **v1.5 Swagger 2.0 Body Schema Support** - Phases 7-9 (shipped 2026-01-29)
- ✅ **v1.6 Unified Stub Generation Pipeline** - Phase 10 (shipped 2026-01-30)
- ✅ **v1.7 Documentation Refresh** - Phase 11 (shipped 2026-01-29)
- ✅ **v1.8 Testing Infrastructure** - Phases 12-15 (shipped 2026-01-31)
- 🚧 **v1.9 Schema Check Workflow Fix** - Phases 16-18 (in progress)

## Phases

**Phase Numbering:**
- Integer phases (16, 17, 18): Planned milestone work
- Decimal phases (16.1, 16.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 16: CI Fix** - Fix unicode_map dependency breaking load_all() in CI
- [x] **Phase 17: Schema Diffing** - Add endpoint-level diff with breaking change detection
- [ ] **Phase 18: Reliability** - Add timeout protection and graceful failure handling

## Phase Details

### Phase 16: CI Fix
**Goal**: Schema check workflow can load the package in CI without errors
**Depends on**: Nothing (prerequisite for other work)
**Requirements**: CI-01, CI-02, CI-03, CI-04
**Success Criteria** (what must be TRUE):
  1. User can run pkgload::load_all() in CI without usethis dependency error
  2. Unicode map data is available via sysdata.rda after package installation
  3. R/unicode_map.R no longer exists in the R/ directory
  4. data-raw/unicode_map.R script generates sysdata.rda when executed
**Plans**: 1 plan

Plans:
- [x] 16-01-PLAN.md — Move unicode_map to data-raw/ and update CI workflow

### Phase 17: Schema Diffing
**Goal**: Workflow reports which specific endpoints changed and whether changes are breaking
**Depends on**: Phase 16
**Requirements**: DIFF-01, DIFF-02, DIFF-03
**Success Criteria** (what must be TRUE):
  1. User can see which specific endpoints were added, removed, or modified in workflow output
  2. User can distinguish breaking changes (removed endpoints, changed params) from non-breaking changes (new endpoints)
  3. Auto-generated PR body includes structured endpoint-level diff summary with breaking/non-breaking classification
**Plans**: 2 plans

Plans:
- [x] 17-01-PLAN.md — Create schema diff engine with endpoint-level comparison and breaking change classification
- [x] 17-02-PLAN.md — Integrate diff engine into CI workflow and update PR body template

### Phase 18: Reliability
**Goal**: Workflow handles API failures gracefully without blocking development
**Depends on**: Phase 16
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. Schema download functions timeout after configurable duration instead of hanging indefinitely
  2. Workflow completes with warning status when schemas unavailable (not failure status)
  3. Expected 404s from brute-force path discovery are logged as info, not errors
  4. Actual API failures (network errors, 500s) are clearly reported as warnings
**Plans**: 1 plan

Plans:
- [ ] 18-01-PLAN.md — Add timeout protection to schema downloads and make CI workflow resilient to failures

## Progress

**Execution Order:**
Phases execute in numeric order: 16 → 17 → 18

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 16. CI Fix | v1.9 | 1/1 | ✓ Complete | 2026-02-12 |
| 17. Schema Diffing | v1.9 | 2/2 | ✓ Complete | 2026-02-12 |
| 18. Reliability | v1.9 | 0/1 | Not started | - |
