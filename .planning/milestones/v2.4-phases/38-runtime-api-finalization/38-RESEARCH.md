---
phase: 38-runtime-api-finalization
status: complete
researched: 2026-04-28
requirements: [RUNT-01, RUNT-02, RUNT-03]
---

# Phase 38 Research: Runtime API Finalization

## RESEARCH COMPLETE

## Question

What needs to be true to plan Phase 38 well?

Phase 38 should finish the query-time API contract for source-backed ECOTOX lifestage output. The implementation surface is small and concentrated in `R/eco_functions.R`, but the contract must be locked by durable tests because it changes user-visible columns.

## Current Runtime Shape

`eco_results()` builds a DuckDB query, enriches metadata through `.eco_enrich_metadata()`, applies conversions, collects, then post-processes.

Relevant current behavior:

- `.eco_enrich_metadata()` joins `lifestage_codes` by `organism_lifestage == code`.
- It then joins `lifestage_dictionary` by `org_lifestage`.
- It currently does not join `lifestage_review`.
- It relocates source-backed lifestage fields after `organism_lifestage`, but omits `source_match_method`.
- Default `eco_results()` currently exposes provenance columns directly.
- `.eco_results_plumber()` returns the Plumber JSON body as a tibble without applying a local compact/detail selector.

This means the implementation is close to the target boundary, but not aligned with the Phase 38 context decisions.

## Contract From Phase Context

The roadmap originally framed RUNT-01 as an 8-column source-backed output. Phase 38 context refines this into two modes:

- Default output is compact and human-facing: `org_lifestage`, `harmonized_life_stage`, `reproductive_stage`.
- `lifestage_details = TRUE` exposes detailed provenance/debug fields: `organism_lifestage`, `source_term_label`, `source_ontology`, `source_term_id`, `source_match_status`, `source_match_method`, `derivation_source`, plus the compact fields.
- `ontology_id` must remain absent in every mode.
- Runtime enrichment must never reference `lifestage_review`.
- Local DuckDB and Plumber routes must apply the same visibility contract.

The plan should explicitly cite D-01 through D-23 so execution cannot silently revert to the older all-provenance default.

## Implementation Findings

### `R/eco_functions.R`

Primary edits should happen here.

Likely implementation shape:

1. Add `lifestage_details = FALSE` to `eco_results()`.
2. Pass `lifestage_details` into `.eco_results_plumber()`.
3. Add the same argument to `.eco_results_plumber()` and include it in the request body where appropriate.
4. Add `source_match_method` to `.eco_enrich_metadata()`'s lifestage relocation.
5. Add a small internal selector/finalizer after collection, for example `.eco_select_lifestage_output(df, lifestage_details)`.
6. In default mode, remove `organism_lifestage` and detailed provenance fields while keeping `org_lifestage`, `harmonized_life_stage`, and `reproductive_stage` in reviewer-friendly order.
7. In detailed mode, order lifestage fields as:
   `org_lifestage`, `harmonized_life_stage`, `reproductive_stage`, `organism_lifestage`, `source_term_label`, `source_ontology`, `source_term_id`, `source_match_status`, `source_match_method`, `derivation_source`.

The selector should use `dplyr::any_of()` or intersected vectors so it can safely handle responses from older Plumber servers while still enforcing the local DuckDB schema guard before local joins.

### Stale Schema Guard

The phase context prefers a clear abort for missing or stale lifestage schema over returning `NA` harmonization columns.

The safest local guard is before joining in `.eco_enrich_metadata()`:

- Verify `lifestage_codes` and `lifestage_dictionary` exist.
- Verify `lifestage_dictionary` has the required source-backed columns, including `source_match_method`.
- Abort with `cli::cli_abort()` and text pointing users to patch or rebuild the ECOTOX DB.

This should remain a local DuckDB guard. Plumber errors should remain server-side transport/API errors, with the client selector still normalizing visibility when a response is returned.

### Tests

The existing `tests/testthat/test-eco_lifestage_gate.R` has a strong temporary DuckDB fixture:

- `make_patch_db(..., with_query_tables = TRUE)` creates the minimal tables needed by `eco_results()`.
- `with_lifestage_files()` lets tests use local CSV fixtures.
- The current "patched DB is readable via eco_results()" test already exercises the local runtime path with a patched DB.

This test is the best place to lock:

- default compact columns and order,
- detailed columns and order,
- `source_match_method` propagation,
- `ontology_id` absence,
- stale schema abort,
- runtime source text does not reference `lifestage_review`.

`tests/testthat/test-eco_functions.R` has live-DB tests that are skipped unless a local DB is available. Update their expected column sets so they do not keep asserting provenance columns in default output.

For Plumber parity, a lightweight unit test can mock or temporarily override the request path if feasible. If the existing package test style makes that awkward, add a small internal selector test instead and ensure `.eco_results_plumber()` calls the same selector as the DuckDB path.

### Documentation

Roxygen in `R/eco_functions.R` currently documents detailed source-backed fields as always present. It must document:

- `@param lifestage_details`,
- compact default output,
- detailed mode fields,
- `ontology_id` absence,
- examples for default and detailed slices if useful.

Regenerate `man/eco_results.Rd` with `devtools::document()`.

## Validation Architecture

Use targeted package tests as the validation contract.

Recommended quick command:

```powershell
Rscript -e "devtools::test(filter='eco_lifestage_gate')"
```

Recommended final command:

```powershell
Rscript -e "devtools::test(filter='eco_(functions|lifestage_gate)')"
```

Documentation regeneration:

```powershell
Rscript -e "devtools::document()"
```

Full `devtools::check()` is deliberately not the Phase 38 narrow gate because the handoff notes a prior full-suite timeout. It remains a broader release gate outside this phase's core acceptance.

## Risks And Pitfalls

| Risk | Planning response |
|------|-------------------|
| Roadmap and context disagree on default output width | Treat `38-CONTEXT.md` as the refined contract and cite D-08 explicitly in the plan |
| Plumber route drifts from local DuckDB route | Use a shared output selector/finalizer and pass `lifestage_details` through the Plumber request body |
| Stale DB returns silent `NA` lifestage fields | Add an explicit local schema guard before joining lifestage tables |
| Tests accidentally require a live ECOTOX DB | Keep the main Phase 38 contract tests on temporary DuckDB fixtures in `test-eco_lifestage_gate.R` |
| `lifestage_review` leaks into runtime | Add a source-level assertion that `.eco_enrich_metadata()` does not reference it |

## Recommended Plan Shape

One plan in one wave is enough:

1. Add/update focused tests for compact default, detailed output, stale schema, `ontology_id` absence, and review-table exclusion.
2. Implement `lifestage_details`, schema guard, `source_match_method`, and shared output selection in `R/eco_functions.R`.
3. Update roxygen, regenerate `man/eco_results.Rd`, and adjust live-DB expectations in `test-eco_functions.R`.
4. Run targeted verification.

