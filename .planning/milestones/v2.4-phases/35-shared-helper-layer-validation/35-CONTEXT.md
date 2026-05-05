# Phase 35: Shared Helper Layer Validation - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Validate all 14 helper functions in `R/eco_lifestage_patch.R` load cleanly and produce correct output shapes. Fix two specific compliance gaps (NVS failure handling, OLS4 prefix filtering) discovered during analysis. BioPortal adapter creation is deferred to a new phase inserted after this one.

</domain>

<decisions>
## Implementation Decisions

### BioPortal Adapter Scope
- **D-01:** BioPortal adapter (PROV-04) is **deferred** — no `.eco_lifestage_query_bioportal()` exists in the current code. Phase 35 validates the 14 functions that exist today. A new phase will be inserted after 35 (before Phase 36) for BioPortal adapter creation and wiring into `.eco_lifestage_resolve_term()`.
- **D-02:** Success criterion 4 (BioPortal fallback-only behavior) cannot be validated in this phase. Mark as deferred in verification.

### NVS Failure Handling Fix
- **D-03:** Fix `.eco_lifestage_nvs_index()` to wrap the HTTP call in `tryCatch`, change `cli_abort` to `cli_warn` on failure, and return an empty tibble. Currently NVS failure crashes the entire resolve pipeline including OLS4 results.
- **D-04:** The fix ensures OLS4 candidates survive when NVS is unreachable. NVS-only terms land in `lifestage_review` as unresolved/ambiguous — correct quarantine behavior.

### OLS4 Prefix Post-Filtering Fix
- **D-05:** Add `obo_id` prefix post-filtering to `.eco_lifestage_query_ols4()`. After the existing NA filter, add a `dplyr::filter()` that checks `source_term_id` starts with the expected ontology prefix (e.g., `UBERON:` or `PO:`). Prevents cross-ontology contamination from OLS4 search results.

### Provider Error Resilience
- **D-06:** Apply the same tryCatch + `cli_warn` + empty tibble pattern to `.eco_lifestage_query_ols4()` HTTP calls. All provider adapters become individually resilient — any single provider going down doesn't kill the pipeline.

### Validation Strategy
- **D-07:** Write a `dev/` validation script that calls each adapter with known terms (e.g., "Adult", "Larva"), checks output shapes/column names, and verifies scoring tiers. Live API calls for realistic validation.
- **D-08:** NVS failure simulation: temporarily override the NVS SPARQL URL to a non-existent host in the script, confirm `cli_warn` fires and empty tibble returns, then restore.
- **D-09:** Validation also includes `devtools::load_all()` confirming no errors/warnings from `eco_lifestage_patch.R`.

### Claude's Discretion
- Dev script naming and structure within `dev/`
- Exact test terms used for live adapter validation
- Order of validation checks in the script
- Whether to test OLS4 failure simulation in addition to NVS (both have tryCatch now)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Implementation Plan
- `LIFESTAGE_HARMONIZATION_PLAN2.md` — v2.4 source-backed resolution plan (the active plan)

### Key Source Files
- `R/eco_lifestage_patch.R` — Shared helper layer (926 lines, 14 functions) — the primary target of this phase
- `R/eco_functions.R` — Runtime enrichment (`.eco_enrich_metadata()` join)
- `inst/extdata/ecotox/lifestage_baseline.csv` — Committed baseline CSV
- `inst/extdata/ecotox/lifestage_derivation.csv` — Derivation mapping CSV

### Test Files
- `tests/testthat/test-eco_lifestage_gate.R` — Existing v2.4 patch pipeline tests (leave as-is)

### Prior Phase Context
- `.planning/phases/34-teardown/34-CONTEXT.md` — Phase 34 decisions (teardown complete, DB clean)

</canonical_refs>

<code_context>
## Existing Code Insights

### Functions to Validate (14 total)
1. `.eco_lifestage_cache_schema()` — 13-column cache schema definition
2. `.eco_lifestage_dictionary_schema()` — 13-column dictionary schema definition
3. `.eco_lifestage_review_schema()` — 9-column review schema definition
4. `.eco_lifestage_release_id()` — Extract release ID from DB or path
5. `.eco_lifestage_cache_path()` — Compute release-scoped cache file path
6. `.eco_lifestage_baseline_path()` — Locate committed baseline CSV
7. `.eco_lifestage_derivation_path()` — Locate committed derivation CSV
8. `.eco_lifestage_read_csv()` — Read CSV with NA handling
9. `.eco_lifestage_validate_cache()` — Validate cache schema and release match
10. `.eco_lifestage_cache_read()` / `.eco_lifestage_cache_write()` — Read/write release-scoped cache
11. `.eco_lifestage_derivation_map()` — Load and validate derivation CSV
12. `.eco_lifestage_load_seed_cache()` — 4-mode seed loading (auto/cache/baseline/live)
13. `.eco_lifestage_materialize_tables()` — Full materialization orchestrator
14. `.eco_patch_lifestage()` — Main entry point for in-place DB patching

### Provider Adapters (need fixes)
- `.eco_lifestage_query_ols4()` (line 498) — Missing obo_id prefix post-filter; missing tryCatch
- `.eco_lifestage_nvs_index()` (line 440) — Uses cli_abort instead of cli_warn; missing tryCatch on HTTP call
- `.eco_lifestage_query_nvs()` (line 548) — Local filter against NVS index (no fix needed)

### Scoring/Ranking Pipeline (validate only)
- `.eco_lifestage_normalize_term()` — Strict and loose normalization
- `.eco_lifestage_score_text()` — 100/90/75 tier scoring
- `.eco_lifestage_token_score()` — Token/boundary matching
- `.eco_lifestage_rank_candidates()` — Candidate ranking + resolved/ambiguous/unresolved status
- `.eco_lifestage_resolve_term()` — Orchestrates OLS4 + NVS + ranking

### Integration Points
- `.eco_lifestage_review_from_cache()` — Builds review table from non-resolved cache rows
- `.eco_lifestage_derive_fields()` — Joins resolved rows against derivation map

</code_context>

<specifics>
## Specific Ideas

No specific requirements — standard validation + surgical fixes approach.

</specifics>

<deferred>
## Deferred Ideas

- **BioPortal adapter creation** — New phase to be inserted after Phase 35 (before Phase 36). Must create `.eco_lifestage_query_bioportal()` and wire it into `.eco_lifestage_resolve_term()` as a fallback provider (PROV-04). Requires roadmap update via `/gsd-add-phase`.

</deferred>

---

*Phase: 35-shared-helper-layer-validation*
*Context gathered: 2026-04-22*
