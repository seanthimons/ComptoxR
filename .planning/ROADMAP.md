# Roadmap: ComptoxR

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
- v2.1 Test Infrastructure - Phases 23-26 (shipped 2026-03-02, verified 2026-03-09)
- v2.2 Package Stabilization - Phases 27-30 (shipped 2026-03-11)
- v2.3 ECOTOX Lifestage Harmonization - Phases 31-33 (shipped 2026-04-21)
- v2.4 Source-Backed Lifestage Resolution - Phases 34-39 (shipped 2026-05-05)

## Current Position

No active milestone is open. Start the next planning cycle with `$gsd-new-milestone`.

## Shipped Phase Groups

| Milestone | Scope | Status | Archive |
|-----------|-------|--------|---------|
| v1.0-v1.9 | Stub generation, schema parsing, docs, CI, and test infrastructure foundations | Shipped | `.planning/milestones/` |
| v2.0 | Auto-pagination engine for generated wrappers | Shipped | `.planning/milestones/` |
| v2.1 | Test infrastructure overhaul and pagination coverage | Shipped | `.planning/milestones/v2.1-ROADMAP.md` |
| v2.2 | Package stabilization | Shipped | `.planning/milestones/v2.2-ROADMAP.md` |
| v2.3 | Initial ECOTOX lifestage harmonization | Shipped | `.planning/MILESTONES.md` |
| v2.4 | Source-backed ECOTOX lifestage resolution, patch seed workflow, runtime API finalization | Shipped | `.planning/milestones/v2.4-ROADMAP.md` |

## v2.4 Summary

v2.4 replaced the v2.3 regex-first lifestage approach with a source-backed patch seed workflow. It removed the old `ontology_id` runtime surface, rebuilt lifestage patching around deterministic package artifacts, finalized compact/default and detailed `eco_results()` lifestage output, and added mocked provider tests for OLS4, NVS, and BioPortal.

The full v2.4 roadmap and requirement traceability are archived in:

- `.planning/milestones/v2.4-ROADMAP.md`
- `.planning/milestones/v2.4-REQUIREMENTS.md`

## Next Milestone

Not planned yet.