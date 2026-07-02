# Quick Task 260421: Reframe ECOTOX Lifestage Build Around Source-Backed Mapping

## Objective
Replace the current section 16 lifestage build with a source-backed mapping pipeline where canonical lifestage data is a reviewed raw-term-to-authoritative-source mapping, and `harmonized_life_stage` is only a derived convenience layer.

This plan is intended to be handed to a fresh execution instance.

## Current State
The repo does not implement this architecture yet.

Current behavior:
- [data-raw/ecotox.R](/C:/Users/sxthi/Documents/ComptoxR/data-raw/ecotox.R:975) and [inst/ecotox/ecotox_build.R](/C:/Users/sxthi/Documents/ComptoxR/inst/ecotox/ecotox_build.R:975) still define a hand-authored 5-column dictionary plus regex fallback gate.
- [R/eco_functions.R](/C:/Users/sxthi/Documents/ComptoxR/R/eco_functions.R:653) still joins `lifestage_dictionary` as:
  `org_lifestage`, `harmonized_life_stage`, `ontology_id`, `reproductive_stage`, `classification_source`.
- [dev/lifestage/validate_lifestage.R](/C:/Users/sxthi/Documents/ComptoxR/dev/lifestage/validate_lifestage.R:1), [dev/lifestage/confirm_gate.R](/C:/Users/sxthi/Documents/ComptoxR/dev/lifestage/confirm_gate.R:1), and [tests/testthat/test-eco_lifestage_gate.R](/C:/Users/sxthi/Documents/ComptoxR/tests/testthat/test-eco_lifestage_gate.R:1) still validate the regex-first harmonization model.

Do not assume any source-backed cache, provider lookup, or canonical-source schema already exists.

## Target State
Keep the table name `lifestage_dictionary`, but repurpose it as the canonical source-backed mapping table with these columns:
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

Repurpose `lifestage_review` as a quarantine table with these columns:
- `org_lifestage`
- `candidate_source_ontology`
- `candidate_source_term_id`
- `candidate_source_term_label`
- `candidate_score`
- `candidate_reason`
- `source_provider`
- `ecotox_release`
- `review_status`

Add a runtime cache at:
- `tools::R_user_dir("ComptoxR", "cache")/ecotox/lifestage/<ecotox_release>.csv`

Optional bootstrap artifact:
- `inst/extdata/ecotox/lifestage_baseline.csv`

Update `eco_results()` so it still returns compatibility fields, but additionally exposes:
- `source_ontology`
- `source_term_id`
- `source_term_label`
- `source_match_status`

`ontology_id` should be deprecated or temporarily aliased, not treated as the canonical identifier.

## Non-Negotiable Rules
- Canonical mapping must come from source-backed rows, never from regex-first harmonization.
- `harmonized_life_stage` and `reproductive_stage` are derived-only fields.
- Unresolved or ambiguous source matches must quarantine into `lifestage_review`.
- The build may continue with `cli::cli_alert_warning()`, but it must never silently invent canonical mappings.
- Cache must be ECOTOX-release-aware.
- Both build script copies must remain in sync:
  [data-raw/ecotox.R](/C:/Users/sxthi/Documents/ComptoxR/data-raw/ecotox.R)
  and
  [inst/ecotox/ecotox_build.R](/C:/Users/sxthi/Documents/ComptoxR/inst/ecotox/ecotox_build.R)

## Phase 1: Design The Source-Backed Data Model
Deliverable: agreed schema and helper surface before build-script edits.

Tasks:
1. Add an internal schema spec section or helper definitions for the new canonical and review-table columns.
2. Define the ECOTOX release signature format extracted from the downloaded archive name/date.
3. Decide whether `ontology_id` is:
   - deprecated immediately and removed from runtime output, or
   - retained for one transition release as an alias of `source_term_id`.
4. Define exactly how derived fields are computed from resolved source rows:
   - `harmonized_life_stage`
   - `reproductive_stage`
   - `derivation_source`
5. Document miss-policy semantics:
   - `resolved`
   - `ambiguous`
   - `unresolved`

Acceptance:
- A fresh reader can tell which fields are canonical, which are derived, and which conditions send a row to quarantine.

## Phase 2: Add Release, Cache, And Provider Helpers
Deliverable: internal helpers for release-aware cache lookup and live provider resolution.

Likely file targets:
- [data-raw/ecotox.R](/C:/Users/sxthi/Documents/ComptoxR/data-raw/ecotox.R)
- [inst/ecotox/ecotox_build.R](/C:/Users/sxthi/Documents/ComptoxR/inst/ecotox/ecotox_build.R)
- optionally a new helper file under `R/` if some logic is shared at runtime

Tasks:
1. Add helper to derive `ecotox_release` from the selected ECOTOX archive.
2. Add helper to compute the cache path under `tools::R_user_dir("ComptoxR", "cache")`.
3. Add cache read/write helpers for release-matched CSVs.
4. Add provider clients for:
   - OLS4 for `UBERON`
   - OLS4 for `PO`
   - NERC NVS for `BODC S11`
5. Add candidate normalization and ranking helpers.
6. Add a resolver that returns:
   - resolved canonical row(s), or
   - quarantine candidate row(s)
7. Ensure provider metadata is captured:
   - provider name
   - ontology
   - source release/version when available

Acceptance:
- Given a raw ECOTOX term and release signature, the helper layer can either return a release-matched cached resolution or attempt a live lookup and shape the result into canonical/review rows.

## Phase 3: Replace Section 16 In Both Build Scripts
Deliverable: section 16 no longer writes the hand-authored harmonization table as canonical.

Tasks:
1. Remove the current static dictionary-as-canonical behavior from section 16 in both build scripts.
2. Replace it with this flow:
   - read `SELECT DISTINCT description FROM lifestage_codes`
   - compute `ecotox_release`
   - load release-matched cache if present
   - otherwise query live providers
   - write canonical resolved rows to `lifestage_dictionary`
   - write unresolved/ambiguous candidates to `lifestage_review`
   - derive convenience fields only for resolved rows
   - emit `cli::cli_alert_warning()` when review rows exist
3. Ensure cache is refreshed after successful live lookup.
4. Keep both section 16 copies byte-for-byte aligned after implementation.

Acceptance:
- No hand-authored raw-to-category tribble remains as the canonical artifact in section 16.
- A build with unresolved terms completes with warnings and quarantine rows, not invented mappings.

## Phase 4: Update Query-Time Enrichment And Compatibility
Deliverable: runtime output reflects the new canonical/source-backed model.

Primary file:
- [R/eco_functions.R](/C:/Users/sxthi/Documents/ComptoxR/R/eco_functions.R:653)

Tasks:
1. Update `.eco_enrich_metadata()` to join the repurposed `lifestage_dictionary`.
2. Relocate the new canonical columns ahead of derived convenience columns.
3. Decide and implement compatibility handling for `ontology_id`.
4. Update roxygen and generated docs for `eco_results()`.
5. Confirm `lifestage_review` is never joined into user-facing output.

Acceptance:
- `eco_results()` returns source-backed canonical fields and still preserves compatibility where intended.

## Phase 5: Replace The Dev/Test Story
Deliverable: tests validate the source-backed pipeline, not the old regex-first dictionary.

Primary files:
- [dev/lifestage/validate_lifestage.R](/C:/Users/sxthi/Documents/ComptoxR/dev/lifestage/validate_lifestage.R:1)
- [dev/lifestage/confirm_gate.R](/C:/Users/sxthi/Documents/ComptoxR/dev/lifestage/confirm_gate.R:1)
- [tests/testthat/test-eco_lifestage_gate.R](/C:/Users/sxthi/Documents/ComptoxR/tests/testthat/test-eco_lifestage_gate.R:1)

Tasks:
1. Replace dictionary-completeness validation with source-mapping validation.
2. Add cache-hit path coverage.
3. Add no-cache live-refresh path coverage.
4. Add ambiguous-candidate quarantine coverage.
5. Add unresolved-term quarantine coverage.
6. Add fast rebuild path coverage after cache edit.
7. Remove assumptions that keyword-classified rows are canonical.

Acceptance:
- Test names, assertions, and dev scripts all describe source-backed mapping and quarantine behavior.

## Suggested Execution Order
1. Finalize schema and compatibility policy.
2. Build helper layer and provider/cache adapters.
3. Implement section 16 in one build script.
4. Mirror to the second build script and diff for exact sync.
5. Update runtime enrichment.
6. Rewrite tests/dev scripts.
7. Run end-to-end rebuild and runtime verification.

## Verification Checklist
- Rebuild with exact cache for current ECOTOX release uses cache only and writes no review rows.
- Rebuild with no cache performs live lookup, writes cache, and builds canonical source-backed rows.
- A clearly resolved term lands in `lifestage_dictionary` with `source_match_status = "resolved"`.
- An ambiguous term lands in `lifestage_review` and emits `cli::cli_alert_warning()`.
- An unresolved term lands in `lifestage_review` and does not receive invented canonical fields.
- Editing the cache file and rebuilding reuses the cache without live re-query.
- `eco_results(casrn = "50-29-3")` returns `org_lifestage`, `source_ontology`, `source_term_id`, `source_term_label`, `source_match_status`, plus compatibility fields as designed.
- `.eco_enrich_metadata()` never joins `lifestage_review`.
- Scoped `devtools::check()` still returns 0 errors.

## Risks To Manage
- Provider response formats may differ substantially between OLS4 and NVS.
- Ontology releases may not expose version metadata uniformly.
- Matching quality/ranking will need careful review for botanical and aquatic terms.
- Network-dependent tests must be isolated from deterministic cache-path tests.
- Backward compatibility around `ontology_id` must be explicit to avoid silent breakage.

## Success Criteria
- Canonical lifestage rows in the built DB are source-backed and provenance-carrying.
- Derived convenience fields exist, but are not treated as the source of truth.
- Release-aware cache enables unattended rebuilds after the first reviewed refresh.
- Ambiguous and unresolved terms are quarantined visibly, not flattened into invented canonical mappings.

## Handoff Note
The executing instance should begin by re-reading the current section 16 implementations and [R/eco_functions.R](/C:/Users/sxthi/Documents/ComptoxR/R/eco_functions.R:653) to confirm the baseline before editing. It should treat this as new work, not an extension of the already-completed v2.3 closeout.
