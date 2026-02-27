# Roadmap: ComptoxR Test Infrastructure

## Overview

ComptoxR's stub generation pipeline (v1.9) produces clean API wrappers, but the test infrastructure is broken. The test generator doesn't read actual parameter types or tidy flags from stubs, producing 834+ failing tests and 673 bad VCR cassettes. This milestone fixes build blockers, rebuilds the test generator to produce correct tests, cleans up cassettes, and automates the stub-to-test pipeline with CI reporting.

## Milestones

- v1.0 Stub Generation Fix - Phases 1-2 (shipped 2026-01-27)
- v1.1 Raw Text Body Fix - Phase 3 (shipped 2026-01-27)
- v1.2 Bulk Request Body Type Fix - Phase 4 (shipped 2026-01-28)
- v1.3 Chemi Resolver Integration Fix - Phase 5 (shipped 2026-01-28)
- v1.4 Empty POST Endpoint Detection - Phase 6 (shipped 2026-01-29)
- v1.5 Swagger 2.0 Body Schema Support - Phases 7-9 (shipped 2026-01-29)
- v1.6 Unified Stub Generation Pipeline - Phase 10 (shipped 2026-01-30)
- v1.7 Documentation Refresh - Phase 11 (shipped 2026-01-29)
- v1.8 Testing Infrastructure - Phases 12-15 (shipped 2026-01-31)
- v1.9 Schema Check Workflow Fix - Phases 16-18 (shipped 2026-02-12)
- v2.0 Paginated Requests - Phases 19-21 (shipped 2026-02-24)
- **v2.1 Test Infrastructure** - Phases 23-26 (current)

## Phases

**Phase Numbering:**
- Integer phases (23, 24, 25, 26): Planned milestone work
- Decimal phases (23.1, 23.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 23: Build Fixes & Test Generator Core** - Fix stub syntax errors and rebuild test generator to read actual metadata (completed 2026-02-27)
- [ ] **Phase 24: VCR Cassette Cleanup** - Delete bad cassettes, add cleanup tools, verify API key filtering
- [ ] **Phase 25: Automated Test Generation Pipeline** - Detect gaps, generate tests, integrate with CI
- [ ] **Phase 26: Pagination Tests & Coverage Hardening** - Add pagination tests and tune coverage thresholds

## Phase Details

### Phase 23: Build Fixes & Test Generator Core
**Goal**: Package builds cleanly and test generator produces correct tests by reading actual function metadata
**Depends on**: Nothing (foundation work)
**Requirements**: BUILD-01, BUILD-02, BUILD-03, BUILD-04, BUILD-05, BUILD-06, BUILD-07, BUILD-08, TGEN-01, TGEN-02, TGEN-03, TGEN-04, TGEN-05
**Success Criteria** (what must be TRUE):
  1. R CMD check produces 0 errors on Windows, macOS, and Linux
  2. Generated test files call functions with correctly typed parameters (DTXSID for query, integer for limit, string for search_type)
  3. Generated tests assert list return type for tidy=FALSE functions and tibble for tidy=TRUE functions
  4. Generated tests include unique cassette names per test variant (single, batch, error, example)
  5. All stub generation syntax bugs fixed (no reserved word collisions, no duplicate args, valid roxygen)
**Plans:** 5 plans (4 complete + 1 gap closure)
Plans:
- [x] 23-01-PLAN.md — Merge PR + non-generator BUILD fixes (license, imports, encoding, httr2, partial match)
- [x] 23-02-PLAN.md — Fix stub generator syntax + schema automation pipeline (Items 2 & 3)
- [x] 23-03-PLAN.md — Build metadata-aware test generator core (all TGEN requirements)
- [x] 23-04-PLAN.md — Purge and regenerate stubs, validate with R CMD check
- [ ] 23-05-PLAN.md — Gap closure: regenerate 6 test files with malformed parameter interpolation

### Phase 24: VCR Cassette Cleanup
**Goal**: Clean cassette infrastructure with verified API key filtering and bulk management tools
**Depends on**: Phase 23 (need correct test generator before re-recording)
**Requirements**: VCR-01, VCR-02, VCR-03, VCR-04, VCR-05, VCR-06, VCR-07
**Success Criteria** (what must be TRUE):
  1. All 673 untracked cassettes with wrong parameters are deleted from the filesystem
  2. Helper functions exist for deleting cassettes (all, by pattern, by function name)
  3. All committed cassettes show `<<<API_KEY>>>` placeholder, never actual keys
  4. Documentation exists for batched cassette re-recording (20-50 at a time with delays)
  5. High-priority functions (hazard, exposure, chemical domains) have clean cassettes re-recorded
**Plans**: TBD

### Phase 25: Automated Test Generation Pipeline
**Goal**: CI detects stub-test gaps and automatically generates missing tests after stub creation
**Depends on**: Phase 23 (test generator working), Phase 24 (cassette management in place)
**Requirements**: AUTO-01, AUTO-02, AUTO-03, AUTO-04, AUTO-05, AUTO-06
**Success Criteria** (what must be TRUE):
  1. Running `dev/detect_test_gaps.R` outputs list of functions lacking test files
  2. Running `dev/generate_tests.R` creates test files for all detected gaps
  3. GitHub Action workflow triggers after stub generation and commits new test files
  4. CI workflow summary shows test gap count and coverage metrics
  5. Generated stubs marked `@lifecycle stable` are protected from test generator overwrites
  6. Test generation is integrated into stub workflow: generate stubs → detect gaps → generate tests → commit together
**Plans**: TBD

### Phase 26: Pagination Tests & Coverage Hardening
**Goal**: Pagination functionality verified by tests and coverage thresholds tuned for generated code
**Depends on**: Phase 25 (automated test generation working)
**Requirements**: PAG-20, PAG-21, PAG-22, PAG-23
**Success Criteria** (what must be TRUE):
  1. Unit tests verify all 5 pagination regex patterns detect correctly from real schemas
  2. Unit tests verify each pagination strategy (offset/limit, page/size, cursor, path-based) with mocked responses
  3. At least one integration test runs paginated stub end-to-end with VCR cassettes
  4. All existing non-pagination tests continue to pass (no regression)
  5. Coverage configuration excludes auto-generated defensive code or uses tiered thresholds (R/ >=75%, dev/ >=80%, stubs >=50%)
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 23 → 24 → 25 → 26

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 23. Build Fixes & Test Generator Core | 4/4 | Complete   | 2026-02-27 | - |
| 24. VCR Cassette Cleanup | v2.1 | 0/TBD | Not started | - |
| 25. Automated Test Generation Pipeline | v2.1 | 0/TBD | Not started | - |
| 26. Pagination Tests & Coverage Hardening | v2.1 | 0/TBD | Not started | - |
