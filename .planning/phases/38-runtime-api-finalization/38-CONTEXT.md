# Phase 38: Runtime API Finalization - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Finalize the `eco_results()` runtime API for source-backed lifestage enrichment. This phase locks the user-facing output contract, ensures `ontology_id` is absent, ensures runtime enrichment joins only `lifestage_dictionary`, and verifies the same public contract across local DuckDB and Plumber-backed `eco_results()` routes.

This phase does not reopen ontology selection, semantic adjudication, build/patch orchestration, or public patch API design. Phase 37 owns patch/build integration; Phase 38 owns the query-time API surface.

</domain>

<decisions>
## Implementation Decisions

### Compact default lifestage output
- **D-01:** `eco_results()` should be compact by default for human reviewers.
- **D-02:** Default output should expose only these lifestage-facing columns: `org_lifestage`, `harmonized_life_stage`, and `reproductive_stage`.
- **D-03:** `organism_lifestage` is useful join/debug machinery, but not useful human-facing output. Use it internally for the join and hide it from default `eco_results()` output.
- **D-04:** `ontology_id` remains absent from all `eco_results()` output modes.

### Lifestage details flag
- **D-05:** Add `lifestage_details = FALSE` to `eco_results()`.
- **D-06:** When `lifestage_details = TRUE`, include the extra curation/provenance/debug fields.
- **D-07:** Detailed mode should include `organism_lifestage`, `source_term_label`, `source_ontology`, `source_term_id`, `source_match_status`, `source_match_method`, and `derivation_source` in addition to the compact human-facing columns.
- **D-08:** Phase 38's original 8-column source-backed contract should be validated through `lifestage_details = TRUE`, not through the compact default output. Tests and docs should reflect this refinement.

### Column ordering
- **D-09:** In default output, place the compact lifestage block in a reviewer-friendly order: `org_lifestage`, `harmonized_life_stage`, `reproductive_stage`.
- **D-10:** In detailed output, keep the human-facing columns first, then append join/provenance/debug fields: `org_lifestage`, `harmonized_life_stage`, `reproductive_stage`, `organism_lifestage`, `source_term_label`, `source_ontology`, `source_term_id`, `source_match_status`, `source_match_method`, `derivation_source`.
- **D-11:** Current code is close but not fully aligned: `source_match_method` is missing from `eco_results()` output/tests/docs, and current ordering follows the older all-provenance block.

### Missing or stale schema behavior
- **D-12:** `eco_results()` may assume a patched v2.4 ECOTOX DB in normal operation.
- **D-13:** If required lifestage tables or columns are missing, abort clearly rather than returning `NA` harmonization columns.
- **D-14:** Treat stale schema handling as an invariant check for development and cached DB edge cases, not as a normal recovery path.
- **D-15:** Error text should point users toward patching or rebuilding the ECOTOX DB. Phase 38 does not need to invent a new recovery workflow.

### Backend parity
- **D-16:** The compact/default and `lifestage_details = TRUE` contract applies to every `eco_results()` route, including `.eco_results_plumber()`.
- **D-17:** There should not be a backend-specific exception where local DuckDB and Plumber outputs have different lifestage column visibility.

### Runtime join boundary
- **D-18:** `.eco_enrich_metadata()` must join `lifestage_codes` and `lifestage_dictionary` only.
- **D-19:** `.eco_enrich_metadata()` must never join or reference `lifestage_review`; review rows are quarantine/audit data, not runtime enrichment data.

### Verification strategy
- **D-20:** Use durable testthat coverage for the API contract: compact default output, detailed output, `ontology_id` absence, `lifestage_review` absence from runtime joins, stale-schema abort, and Plumber parity where feasible.
- **D-21:** Verification should use a very limited devtools/testthat check focused on this runtime surface, not the full build and full package test suite.
- **D-22:** A dedicated `dev/lifestage/validate_38.R` script is not required unless planning finds a concrete gap that testthat cannot express cleanly.
- **D-23:** Full `devtools::check()` remains useful as a broader release gate, but it should not be the narrow Phase 38 acceptance mechanism if it implies the full build/test suite.

### Agent's Discretion
- Exact implementation mechanics for hiding default columns, provided `organism_lifestage` remains available in detailed mode for debugging/provenance.
- Exact test file placement between `tests/testthat/test-eco_functions.R` and `tests/testthat/test-eco_lifestage_gate.R`.
- Exact limited verification command, provided it exercises the Phase 38 runtime contract without running the full build/test suite.

</decisions>

<specifics>
## Specific Ideas

Default lifestage slice:

```r
eco_results(casrn = "50-29-3") |>
  dplyr::select(org_lifestage, harmonized_life_stage, reproductive_stage)
```

Detailed lifestage slice:

```r
eco_results(casrn = "50-29-3", lifestage_details = TRUE) |>
  dplyr::select(
    org_lifestage,
    harmonized_life_stage,
    reproductive_stage,
    organism_lifestage,
    source_term_label,
    source_ontology,
    source_term_id,
    source_match_status,
    source_match_method,
    derivation_source
  )
```

The user specifically pushed back on preserving `organism_lifestage` for compatibility: there are no existing users, so broad output cleanup is acceptable. Human reviewers need the decoded original lifestage label, not the ECOTOX code.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` - Phase 38 goal and success criteria for `eco_results()` runtime output, `ontology_id` absence, and `lifestage_dictionary`-only joins.
- `.planning/REQUIREMENTS.md` - RUNT-01 through RUNT-03 requirements.
- `.planning/PROJECT.md` - v2.4 milestone goal and source-backed lifestage scope.
- `.planning/STATE.md` - Current project position: Phase 38 ready for planning after Phase 37.

### Prior Phase Context
- `.planning/phases/37-build-patch-integration/37-CONTEXT.md` - Patch/build integration, refresh behavior, and metadata decisions that Phase 38 should not reopen.
- `.planning/phases/36.2-dictionary-rebuild-validation/36.2-CONTEXT.md` - Semantic adjudication, derivation policy, and source-backed dictionary context.
- `.planning/phases/36.1-unresolved-coverage-audit/36.1-CONTEXT.md` - Review/quarantine semantics for unresolved lifestage terms.

### Product Code and Tests
- `R/eco_functions.R` - `eco_results()`, `.eco_results_plumber()`, and `.eco_enrich_metadata()` runtime output path.
- `R/eco_lifestage_patch.R` - Source-backed lifestage table schemas and materialization helpers.
- `tests/testthat/test-eco_functions.R` - Existing `eco_results()` tests and live DB schema checks.
- `tests/testthat/test-eco_lifestage_gate.R` - Existing patched DB readability test through `eco_results()`.
- `man/eco_results.Rd` - Generated documentation that must reflect `lifestage_details` and the compact/detailed output contract.

### Design and Handoff
- `LIFESTAGE_HARMONIZATION_PLAN2.md` - Original runtime enrichment design: remove `ontology_id`, never join `lifestage_review`, and expose source-backed lifestage fields.
- `HANDOFF.md` - Current lifestage handoff and warnings against reopening ontology expansion.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `eco_results()` already routes through DuckDB or `.eco_results_plumber()`.
- `.eco_enrich_metadata()` already joins `lifestage_codes`, then `lifestage_dictionary`.
- `.eco_enrich_metadata()` currently does not join `lifestage_review`.
- Existing tests already assert that `ontology_id` is absent from local `eco_results()` output.
- `tests/testthat/test-eco_lifestage_gate.R` already has a temporary patched DuckDB fixture with query tables for runtime testing.

### Established Patterns
- User-facing failures use `cli::cli_abort()`.
- Testthat tests are the durable package gates; dev scripts are used only when they add meaningful human-readable validation.
- Tests can use temporary DuckDB fixtures and `withr::with_envvar(c(eco_burl = db_path), ...)` to exercise local `eco_results()` behavior.
- Existing lifestage tests favor mocked/local artifacts over live provider calls.

### Integration Points
- `eco_results()` needs a new `lifestage_details` argument and documentation.
- `.eco_results_plumber()` must apply the same compact/detailed output contract as the local DuckDB route.
- `.eco_enrich_metadata()` should include `source_match_method` when detailed output is requested.
- Default output cleanup must remove or deselect `organism_lifestage` after it has served its join purpose.
- Tests should inspect source text or generated query behavior enough to ensure `lifestage_review` is not referenced by the runtime enrichment path.

</code_context>

<deferred>
## Deferred Ideas

- A public exported patch/rebuild API remains out of scope.
- A dedicated `dev/lifestage/validate_38.R` script is deferred unless testthat cannot cover the runtime contract clearly.
- Full package `devtools::check()` remains a later release-level gate if needed, not the narrow Phase 38 acceptance path.

</deferred>

---

*Phase: 38-runtime-api-finalization*
*Context gathered: 2026-04-28*
