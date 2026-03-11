# Roadmap: ComptoxR Stub Generation Pipeline

## Milestones

- v1.0 Stub Generation Fix — Phases 1-2 (shipped 2026-01-27)
- v1.1 Raw Text Body Fix — Phase 3 (shipped 2026-01-27)
- v1.2 Bulk Request Body Type Fix — Phase 4 (shipped 2026-01-28)
- v1.3 Chemi Resolver Integration Fix — Phase 5 (shipped 2026-01-28)
- v1.4 Empty POST Endpoint Detection — Phase 6 (shipped 2026-01-29)
- v1.5 Swagger 2.0 Body Schema Support — Phases 7-9 (shipped 2026-01-29)
- v1.6 Unified Stub Generation Pipeline — Phase 10 (shipped 2026-01-30)
- v1.7 Documentation Refresh — Phase 11 (shipped 2026-01-29)
- v1.8 Testing Infrastructure — Phases 12-15 (shipped 2026-01-31)
- v1.9 Schema Check Workflow Fix — Phases 16-18 (shipped 2026-02-12)
- v2.0 Paginated Requests — Phases 19-21 (shipped 2026-02-24)
- v2.1 Test Infrastructure — Phases 23-26 (shipped 2026-03-02, verified 2026-03-09)
- v2.2 Package Stabilization — Phases 27-30 (active)

## Phases

<details>
<summary>v1.0-v1.9 (Phases 1-18) — SHIPPED</summary>

- [x] Phase 1: Fix Body Parameter Extraction (2/2 plans) — completed 2026-01-27
- [x] Phase 2: Validate and Regenerate (2/2 plans) — completed 2026-01-27
- [x] Phase 3: Raw Text Body (2/2 plans) — completed 2026-01-27
- [x] Phase 4: JSON Body Default (3/3 plans) — completed 2026-01-28
- [x] Phase 5: Resolver Integration Fix (1/1 plan) — completed 2026-01-28
- [x] Phase 6: Empty POST Detection (1/1 plan) — completed 2026-01-29
- [x] Phase 7: Version Detection (2/2 plans) — completed 2026-01-29
- [x] Phase 8: Reference Resolution (2/2 plans) — completed 2026-01-29
- [x] Phase 9: Integration Validation (1/1 plan) — completed 2026-01-29
- [x] Phase 10: Pipeline Consolidation (1/1 plan) — completed 2026-01-30
- [x] Phase 11: Documentation Update (1/1 plan) — completed 2026-01-29
- [x] Phase 12: Test Infrastructure Setup (1/1 plan) — completed 2026-01-30
- [x] Phase 13: Unit Tests (2/2 plans) — completed 2026-01-31
- [x] Phase 14: Integration CI (2/2 plans) — completed 2026-01-31
- [x] Phase 15: Integration Test Fixes (1/1 plan) — completed 2026-01-31
- [x] Phase 16: CI Fix (1/1 plan) — completed 2026-02-12
- [x] Phase 17: Schema Diffing (2/2 plans) — completed 2026-02-12
- [x] Phase 18: Reliability (1/1 plan) — completed 2026-02-12

</details>

<details>
<summary>v2.0 Paginated Requests (Phases 19-21) — SHIPPED 2026-02-24</summary>

- [x] Phase 19: Pagination Detection (1/1 plan) — completed 2026-02-24
- [x] Phase 20: Auto-Pagination Engine (2/2 plans) — completed 2026-02-24
- [x] Phase 21: Stub Generation Integration (1/1 plan) — completed 2026-02-24

</details>

<details>
<summary>v2.1 Test Infrastructure (Phases 23-26) — SHIPPED 2026-03-02 (verified 2026-03-09)</summary>

> **Verification note (2026-03-09):** 3 plans had missing summaries due to a documentation
> gap (work was executed but summaries were not written). Retroactive summaries created
> after investigation confirmed all work was completed. Stale 07-version-detection-body-extraction
> directory deleted.

- [x] Phase 23: Build Fixes & Test Generator Core (5/5 plans) — completed 2026-02-27
- [x] Phase 24: VCR Cassette Cleanup (3/3 plans) — completed 2026-02-27
- [x] Phase 25: Automated Test Generation Pipeline (3/3 plans) — completed 2026-03-01
- [x] Phase 26: Pagination Tests & Coverage Hardening (2/2 plans) — completed 2026-03-01

</details>

### v2.2 Package Stabilization (Phases 27-30) — ACTIVE

**Goal:** Migrate all user-facing ct_* functions to use generated stubs via generic_request(), classify functions by complexity, and get the package to a clean build + passing test state.

- [x] Phase 27: Test Infrastructure Stabilization (completed 2026-03-10)
  - **Goal:** Fix mechanical test blockers (VCR key sanitization, purrr::flatten warning, cassette re-recording) so tests can run reliably
  - **Depends on:** v2.1 verification complete
  - **Requirements:** [INFRA-27-01, INFRA-27-02, INFRA-27-03, INFRA-27-04, INFRA-27-05, INFRA-27-06]
  - **Plans:** 3 plans
    - [ ] 27-01-PLAN.md — NAMESPACE selective imports (eliminate purrr/jsonlite @import)
    - [ ] 27-02-PLAN.md — VCR sanitization, health check script, and parallel recording script
    - [ ] 27-03-PLAN.md — Execute cassette re-recording and validate results

- [x] Phase 28: Thin Wrapper Migration (1/5 complete) (completed 2026-03-11)
  - **Goal:** Build hook injection system and migrate all hand-written ct_* wrappers to generated stubs + hooks, deleting old wrapper files
  - **Depends on:** Phase 27
  - **Requirements:** [HOOK-28-01, HOOK-28-02, HOOK-28-03, HOOK-28-04, HOOK-28-05, HOOK-28-06, HOOK-28-07, HOOK-28-08, HOOK-28-09, HOOK-28-10]
  - **Plans:** 5 plans
    - [x] 28-01-PLAN.md — Hook registry foundation (.HookRegistry, run_hook, YAML config, .onLoad)
    - [ ] 28-02-PLAN.md — Hook primitive functions and unit tests
    - [ ] 28-03-PLAN.md — Delete pure pass-through wrappers and deprecated code
    - [ ] 28-04-PLAN.md — Generator hook parameter injection and remaining wrapper deletion
    - [ ] 28-05-PLAN.md — Stub regeneration, test generator update, full validation

- [ ] Phase 29: Direct Template Migration
  - **Goal:** Migrate medium-complexity functions (ct_prop, ct_related) that use raw httr2 to generic_request()
  - **Depends on:** Phase 28
  - **Plans:** 0 — needs `/gsd:plan-phase 29`

- [ ] Phase 30: Build Quality Validation
  - **Goal:** R CMD check 0 errors/warnings, all migrated functions tested, user-facing functions promoted to @lifecycle stable
  - **Depends on:** Phase 29
  - **Plans:** 0 — needs `/gsd:plan-phase 30`

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Fix Body Parameter Extraction | v1.0 | 2/2 | Complete | 2026-01-27 |
| 2. Validate and Regenerate | v1.0 | 2/2 | Complete | 2026-01-27 |
| 3. Raw Text Body | v1.1 | 2/2 | Complete | 2026-01-27 |
| 4. JSON Body Default | v1.2 | 3/3 | Complete | 2026-01-28 |
| 5. Resolver Integration Fix | v1.3 | 1/1 | Complete | 2026-01-28 |
| 6. Empty POST Detection | v1.4 | 1/1 | Complete | 2026-01-29 |
| 7. Version Detection | v1.5 | 2/2 | Complete | 2026-01-29 |
| 8. Reference Resolution | v1.5 | 2/2 | Complete | 2026-01-29 |
| 9. Integration Validation | v1.5 | 1/1 | Complete | 2026-01-29 |
| 10. Pipeline Consolidation | v1.6 | 1/1 | Complete | 2026-01-30 |
| 11. Documentation Update | v1.7 | 1/1 | Complete | 2026-01-29 |
| 12. Test Infrastructure Setup | v1.8 | 1/1 | Complete | 2026-01-30 |
| 13. Unit Tests | v1.8 | 2/2 | Complete | 2026-01-31 |
| 14. Integration CI | v1.8 | 2/2 | Complete | 2026-01-31 |
| 15. Integration Test Fixes | v1.8 | 1/1 | Complete | 2026-01-31 |
| 16. CI Fix | v1.9 | 1/1 | Complete | 2026-02-12 |
| 17. Schema Diffing | v1.9 | 2/2 | Complete | 2026-02-12 |
| 18. Reliability | v1.9 | 1/1 | Complete | 2026-02-12 |
| 19. Pagination Detection | v2.0 | 1/1 | Complete | 2026-02-24 |
| 20. Auto-Pagination Engine | v2.0 | 2/2 | Complete | 2026-02-24 |
| 21. Stub Generation Integration | v2.0 | 1/1 | Complete | 2026-02-24 |
| 23. Build Fixes & Test Generator Core | v2.1 | 5/5 | Complete | 2026-02-27 |
| 24. VCR Cassette Cleanup | v2.1 | 3/3 | Complete | 2026-02-27 |
| 25. Automated Test Generation Pipeline | v2.1 | 3/3 | Complete | 2026-03-01 |
| 26. Pagination Tests & Coverage Hardening | v2.1 | 2/2 | Complete | 2026-03-01 |
| 27. Test Infrastructure Stabilization | 2/3 | Complete    | 2026-03-10 | — |
| 28. Thin Wrapper Migration | 5/5 | Complete    | 2026-03-11 | — |
| 29. Direct Template Migration | v2.2 | 0/0 | Planned | — |
| 30. Build Quality Validation | v2.2 | 0/0 | Planned | — |
