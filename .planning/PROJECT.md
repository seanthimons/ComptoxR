# ComptoxR

## What This Is

ComptoxR is an R package providing wrappers for USEPA CompTox Chemical Dashboard APIs. The project encompasses both the automated stub generation pipeline and the user-facing package researchers use for chemical hazard assessment, toxicity screening, and environmental fate analysis.

## Core Value

Researchers can query EPA CompTox APIs through stable, well-tested R functions that handle authentication, batching, pagination, and result formatting automatically.

## Current State

**Latest shipped:** v2.4 Source-Backed Lifestage Resolution (2026-05-05)
**Active:** Between milestones - ready to plan the next milestone

## Latest Milestone: v2.4 Source-Backed Lifestage Resolution

v2.4 replaced the v2.3 regex-first ECOTOX lifestage harmonization with a source-backed patch seed workflow and finalized the runtime lifestage API.

Delivered:

- Removed the v2.3 regex classifier path and removed `ontology_id` from `eco_results()` output.
- Shipped deterministic installed lifestage patch seed data.
- Moved source/provenance lifestage artifacts into maintainer-facing `dev/lifestage/` paths.
- Added curation, rebuild, priority ranking, and subset refresh scripts for lifestage maintenance.
- Hardened `.eco_patch_lifestage()` baseline/cache/live behavior and DuckDB retry handling.
- Finalized compact/default and detailed `eco_results()` lifestage output via `lifestage_details = TRUE`.
- Added mocked provider adapter quality gates for OLS4, NVS, and BioPortal.

Source-data note: missing enriched lifestages remain where ECOTOX leaves `tests.organism_lifestage` blank. The join path is correct; imputation for blank source lifestages is future scope.

## Stub Generation Pipeline

The pipeline is functional and automated. Resuming pipeline work, including advanced schema handling, S7 classes, and schema-check refinements, remains deferred until selected as a future milestone.

Key pipeline capabilities:

- Unified schema parsing for OpenAPI 3.0 and Swagger 2.0.
- Auto-pagination engine with offset/limit, page/size, cursor, and path-based strategies.
- Metadata-aware test generator.
- CI schema diffing and stub regeneration workflow.

## Deferred

Package work:

- Blank ECOTOX lifestage imputation or external enrichment for rows where `tests.organism_lifestage` is empty.
- Public `.eco_patch_lifestage()` API, currently internal-only.
- Automated ontology version tracking and update detection.
- EPI Suite / GenRA integration.
- Post-processing recipe system (#120).

Pipeline work:

- Advanced schema handling (ADV-01-04).
- Advanced testing: snapshot tests, performance benchmarks, contract testing.
- S7 class implementation (#29).
- Schema-check workflow improvements (#96).
- Check whether stub generation captures API schema descriptions.

## Requirements

The active milestone requirements file has been archived. Current shipped requirement traceability lives in `.planning/milestones/v2.4-REQUIREMENTS.md`; historical milestones are summarized in `.planning/MILESTONES.md`.

## Key Files

- `R/eco_functions.R` - ECOTOX runtime enrichment and `eco_results()` output.
- `R/eco_lifestage_patch.R` - Lifestage patch helpers, provider adapters, materialization, and patch metadata.
- `inst/extdata/ecotox/lifestage_patch_seed.csv` - Installed deterministic lifestage patch seed.
- `dev/lifestage/` - Maintainer lifestage source, provenance, curation, validation, and rebuild scripts.
- `inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R` - ECOTOX build paths.
- `R/z_generic_request.R` - Core request templates.
- `dev/endpoint_eval/07_stub_generation.R` - Stub generation logic.
- `dev/generate_tests.R` - Test generation script.

## Milestones

| Version | Description | Status |
|---------|-------------|--------|
| v1.0 | Query parameter signatures | Complete |
| v1.1 | Raw text body fix | Complete |
| v1.2 | Bulk request body type fix | Complete |
| v1.3 | Chemi resolver integration fix | Complete |
| v1.4 | Empty POST endpoint detection | Complete |
| v1.5 | Swagger 2.0 body schema support | Complete |
| v1.6 | Unified stub generation pipeline | Complete |
| v1.7 | Documentation refresh | Complete |
| v1.8 | Testing infrastructure | Complete |
| v1.9 | Schema check workflow fix | Complete |
| v2.0 | Paginated requests | Complete |
| v2.1 | Test infrastructure | Complete |
| v2.2 | Package stabilization | Complete |
| v2.3 | ECOTOX Lifestage Harmonization | Complete |
| v2.4 | Source-Backed Lifestage Resolution | Complete |

---
*Last updated: 2026-05-05 - v2.4 milestone shipped*
