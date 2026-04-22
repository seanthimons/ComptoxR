PLEASE IMPLEMENT THIS PLAN:
# ECOTOX Source-Backed Lifestage Mapping With In-Place Patch Support

## Summary
Replace the current regex-first canonical lifestage build with a source-backed resolution pipeline, and support both:
- full-build generation during ECOTOX ETL
- in-place patching of an existing `ecotox.duckdb` by rewriting only `lifestage_dictionary` and `lifestage_review`

The patch entrypoint will be an internal dot-function, available to package code and development workflows but not exported:
- `.eco_patch_lifestage(db_path = eco_path(), refresh = c("auto", "cache", "baseline", "live"), force = FALSE)`

This design avoids full rebuilds when only the lifestage mapping logic or reviewed baseline changes.

## Public API / Interface Changes
`eco_results()` will expose these lifestage fields after `organism_lifestage`:
- `org_lifestage`
- `source_ontology`
- `source_term_id`
- `source_term_label`
- `source_match_status`
- `harmonized_life_stage`
- `reproductive_stage`
- `derivation_source`

`ontology_id` is removed immediately from runtime output and docs.

No new exported patch API is added in this iteration. Patch capability is internal only via `.eco_patch_lifestage()`.

## Database Table Contracts
`lifestage_dictionary` canonical schema:
- `org_lifestage`
- `source_ontology`
- `source_term_id`
- `source_term_label`
- `source_term_definition`
- `source_provider`
- `source_match_method`
- `source_match_status`
- `source_release`
- `ecotox_release`
- `harmonized_life_stage`
- `reproductive_stage`
- `derivation_source`

`lifestage_review` quarantine schema:
- `org_lifestage`
- `candidate_source_ontology`
- `candidate_source_term_id`
- `candidate_source_term_label`
- `candidate_score`
- `candidate_reason`
- `source_provider`
- `ecotox_release`
- `review_status`

Patch metadata keys added to `_metadata`:
- `lifestage_patch_applied_at`
- `lifestage_patch_release`
- `lifestage_patch_method`
- `lifestage_patch_version`

## Implementation Design
### 1. Shared helper layer
Add a shared helper file at [R/eco_lifestage_patch.R](/C:/Users/sxthi/Documents/ComptoxR/R/eco_lifestage_patch.R) for all reusable lifestage patch/build logic.

This file will define:
- `.eco_lifestage_release_id()`
- `.eco_lifestage_cache_path()`
- `.eco_lifestage_cache_read()`
- `.eco_lifestage_cache_write()`
- `.eco_lifestage_baseline_path()`
- `.eco_lifestage_load_seed_cache()`
- `.eco_lifestage_query_ols4()`
- `.eco_lifestage_query_nvs()`
- `.eco_lifestage_normalize_term()`
- `.eco_lifestage_rank_candidates()`
- `.eco_lifestage_resolve_term()`
- `.eco_lifestage_materialize_tables()`
- `.eco_lifestage_derive_fields()`
- `.eco_patch_lifestage()`

Build scripts and tests will call these helpers directly rather than carrying duplicated inline resolver logic.

### 2. Internal cache / baseline schema
Use one normalized cache schema for both user cache and committed baseline:
- `org_lifestage`
- `source_provider`
- `source_ontology`
- `source_term_id`
- `source_term_label`
- `source_term_definition`
- `source_release`
- `source_match_method`
- `source_match_status`
- `candidate_rank`
- `candidate_score`
- `candidate_reason`
- `ecotox_release`

Rules:
- release-scoped cache only
- resolved term: one row with `source_match_status = "resolved"`
- ambiguous term: multiple retained rows with `source_match_status = "ambiguous"`
- unresolved term: one row with `source_match_status = "unresolved"`

## Full-Build Path
### 3. Build script section 16 replacement
Both [data-raw/ecotox.R](/C:/Users/sxthi/Documents/ComptoxR/data-raw/ecotox.R:975) and [inst/ecotox/ecotox_build.R](/C:/Users/sxthi/Documents/ComptoxR/inst/ecotox/ecotox_build.R:975) will replace section 16 with:
1. Source or call the shared lifestage helper layer.
2. Query `SELECT DISTINCT description FROM lifestage_codes ORDER BY description`.
3. Compute `ecotox_release` from `latest_zip`.
4. Resolve from user cache, committed baseline, or live providers.
5. Materialize `lifestage_dictionary` and `lifestage_review`.
6. Write both tables with `overwrite = TRUE`.
7. Emit `cli::cli_alert_warning()` when quarantine rows exist.

Both section 16 copies must remain identical after implementation.

## Patch Path
### 4. Internal patch function contract
Add `.eco_patch_lifestage()` in [R/eco_lifestage_patch.R](/C:/Users/sxthi/Documents/ComptoxR/R/eco_lifestage_patch.R).

Signature:
```r
.eco_patch_lifestage <- function(
  db_path = eco_path(),
  refresh = c("auto", "cache", "baseline", "live"),
  force = FALSE
)
```

Behavior:
1. Validate `db_path` exists.
2. Call `.eco_close_con()` first to avoid patching a DB with an open cached read-only handle.
3. Open the DuckDB file read-write.
4. Read `_metadata` and extract installed `ecotox_release`.
5. Verify `lifestage_codes` exists and contains `description`.
6. Resolve distinct lifestage terms using the installed DB release and selected refresh mode.
7. Replace `lifestage_dictionary` and `lifestage_review` in place.
8. Upsert patch metadata in `_metadata`.
9. Disconnect read-write connection.
10. Call `.eco_close_con()` again so next query gets a fresh handle.

Return value:
- invisible named list with `db_path`, `ecotox_release`, `dictionary_rows`, `review_rows`, `refresh_mode`

### 5. Refresh mode semantics
`refresh = "auto"`:
- use release-matched user cache if present
- else use matching committed baseline
- else perform live lookup
- write resulting cache to user cache

`refresh = "cache"`:
- require release-matched user cache
- abort if cache missing unless `force = TRUE`, in which case fall back to `"auto"`

`refresh = "baseline"`:
- require matching committed baseline
- seed user cache from baseline
- abort if no matching baseline unless `force = TRUE`, in which case fall back to `"auto"`

`refresh = "live"`:
- bypass cache/baseline reads
- perform live lookup
- overwrite release-matched user cache with fresh provider results

### 6. Patch safety checks
`.eco_patch_lifestage()` must abort if:
- `_metadata` is missing or lacks `ecotox_release`
- `lifestage_codes` is missing
- `lifestage_codes.description` is missing
- release-specific cache/baseline rows do not match the installed DB release
- read-write connection cannot be established

`.eco_patch_lifestage()` must not touch any tables except:
- `lifestage_dictionary`
- `lifestage_review`
- `_metadata`

## Resolution And Derivation Policy
### 7. Provider resolution
Provider set:
- OLS4 `UBERON`
- OLS4 `PO`
- NERC NVS `BODC S11`

Scoring:
- `100`: exact normalized label
- `90`: punctuation/plural-normalized exact match
- `75`: token or exact-substring boundary match
- below `75`: non-resolving candidate

Status:
- `resolved`: one clear winner `>= 90`
- `ambiguous`: multiple near-top candidates `>= 75`
- `unresolved`: no acceptable candidate

### 8. Derived fields
Derived fields come only from a curated mapping keyed by `source_ontology + source_term_id`:
- `harmonized_life_stage`
- `reproductive_stage`
- `derivation_source`

If a source-backed resolved row lacks a derivation mapping, it is quarantined as review data instead of entering `lifestage_dictionary`.

No regex over raw ECOTOX terms may contribute to canonical or derived output.

## Runtime Enrichment
### 9. Query-time changes
Update [R/eco_functions.R](/C:/Users/sxthi/Documents/ComptoxR/R/eco_functions.R:653):
- join `lifestage_codes`
- join the repurposed `lifestage_dictionary`
- relocate canonical source fields before derived fields
- remove `ontology_id`
- never join `lifestage_review`

Update roxygen in [R/eco_functions.R](/C:/Users/sxthi/Documents/ComptoxR/R/eco_functions.R:245) and regenerate [man/eco_results.Rd](/C:/Users/sxthi/Documents/ComptoxR/man/eco_results.Rd:49).

## Bootstrap Artifact
### 10. Committed baseline
Add [inst/extdata/ecotox/lifestage_baseline.csv](/C:/Users/sxthi/Documents/ComptoxR/inst/extdata/ecotox/lifestage_baseline.csv).

Requirements:
- uses the normalized cache schema
- covers exactly one ECOTOX release
- includes every distinct current `lifestage_codes.description`
- is reviewed and deterministic
- can seed a cold-start patch/build without live lookup

## Tests And Dev Workflows
### 11. Test coverage
Update:
- [tests/testthat/test-eco_lifestage_gate.R](/C:/Users/sxthi/Documents/ComptoxR/tests/testthat/test-eco_lifestage_gate.R:1)
- [dev/lifestage/validate_lifestage.R](/C:/Users/sxthi/Documents/ComptoxR/dev/lifestage/validate_lifestage.R:1)
- [dev/lifestage/confirm_gate.R](/C:/Users/sxthi/Documents/ComptoxR/dev/lifestage/confirm_gate.R:1)

Add test cases for:
- cache-hit patch path
- baseline-seeded patch path
- live-refresh patch path
- ambiguous term quarantine on patch
- unresolved term quarantine on patch
- patch updates only lifestage tables and `_metadata`
- patch requires valid release metadata
- patched DB is readable via `eco_results()` with new columns
- `ontology_id` absent from output
- build section 16 remains identical in both scripts

### 12. Test strategy
Use mocked provider adapters with `testthat::with_mocked_bindings()` for deterministic CI coverage.

Keep live-provider smoke checks in `dev/lifestage/*` only.

## Acceptance Criteria
- Existing `ecotox.duckdb` can be patched in place without full rebuild.
- Full build and patch paths share the same resolver/materialization logic.
- `lifestage_dictionary` contains only source-backed canonical rows.
- `lifestage_review` contains all ambiguous and unresolved terms.
- `eco_results()` exposes new source-backed fields and no `ontology_id`.
- Patch operation is release-aware and refuses cross-release cache misuse.
- Patch updates only `lifestage_dictionary`, `lifestage_review`, and `_metadata`.

## Verification Scenarios
1. Patch existing DB with matching user cache:
   `lifestage_dictionary` and `lifestage_review` are rewritten from cache only.
2. Patch existing DB with no cache but matching baseline:
   baseline seeds cache, then tables are rewritten.
3. Patch existing DB with `refresh = "live"`:
   live lookup runs, cache refreshes, tables rewrite.
4. Patch existing DB with unresolved terms:
   patch completes with warning and quarantine rows.
5. Query after patch:
   `eco_results(casrn = "50-29-3")` returns new lifestage columns and no `ontology_id`.
6. Full rebuild after implementation:
   resulting lifestage tables match patch-produced tables for the same release.

## Assumptions And Defaults Chosen
- Patch capability is internal only via a dot-function.
- Full rebuild remains supported, but not required for lifestage updates.
- `ontology_id` is removed now, not aliased.
- A committed baseline CSV is included in the first implementation.
- Derived fields are keyed only from curated source IDs.
- Patch metadata is stored in `_metadata` as key-value rows, matching current ECOTOX metadata style.