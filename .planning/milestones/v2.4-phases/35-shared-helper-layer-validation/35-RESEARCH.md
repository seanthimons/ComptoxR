# Phase 35: Shared Helper Layer Validation - Research

**Researched:** 2026-04-22
**Domain:** R package internal functions — HTTP adapter resilience, ontology prefix filtering, scoring validation
**Confidence:** HIGH

## Summary

Phase 35 is a surgical fix-and-validate phase, not a greenfield build. The 926-line `R/eco_lifestage_patch.R` already exists with 14 helper functions. All 8 existing tests in `test-eco_lifestage_gate.R` pass cleanly when the package is loaded via `devtools::load_all()`. Two compliance gaps exist in the live HTTP adapters that must be patched: (1) `.eco_lifestage_nvs_index()` uses `cli_abort` instead of `cli_warn` on HTTP failure and has no `tryCatch` wrapper, and (2) `.eco_lifestage_query_ols4()` lacks a post-filter that strips non-UBERON/non-PO results — confirmed by finding 4 GO: prefix entries in the committed `lifestage_baseline.csv` that were accepted as `source_ontology = "UBERON"` rows.

The scoring/ranking pipeline (100 exact / 90 normalized / 75 token-substring / resolved / ambiguous / unresolved) is already fully implemented and testable via mocked bindings without live network calls. The validation script (`dev/lifestage/validate_lifestage.R`) already exists and provides the live-API check pattern. A new `dev/` script for NVS failure simulation is the primary new artifact.

**Primary recommendation:** Fix the two adapter gaps first (NVS tryCatch + OLS4 prefix filter), then run `devtools::load_all()` for the load gate, then write the validation script exercising all 14 functions with known terms and failure simulation.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** BioPortal adapter (PROV-04) is deferred — no `.eco_lifestage_query_bioportal()` exists. Phase 35 validates the 14 functions that exist today. A new phase will be inserted after 35 (before Phase 36) for BioPortal adapter creation.
- **D-02:** Success criterion 4 (BioPortal fallback-only behavior) cannot be validated in this phase. Mark as deferred in verification.
- **D-03:** Fix `.eco_lifestage_nvs_index()` — wrap HTTP call in `tryCatch`, change `cli_abort` to `cli_warn` on failure, return empty tibble.
- **D-04:** The fix ensures OLS4 candidates survive when NVS is unreachable. NVS-only terms land in `lifestage_review` as unresolved/ambiguous.
- **D-05:** Add `obo_id` prefix post-filtering to `.eco_lifestage_query_ols4()`. After existing NA filter, add `dplyr::filter()` checking `source_term_id` starts with expected ontology prefix (UBERON: or PO:).
- **D-06:** Apply the same tryCatch + `cli_warn` + empty tibble pattern to `.eco_lifestage_query_ols4()` HTTP calls.
- **D-07:** Write a `dev/` validation script that calls each adapter with known terms, checks output shapes/column names, and verifies scoring tiers. Live API calls for realistic validation.
- **D-08:** NVS failure simulation: temporarily override the NVS SPARQL URL to a non-existent host in the script, confirm `cli_warn` fires and empty tibble returns, then restore.
- **D-09:** Validation also includes `devtools::load_all()` confirming no errors/warnings from `eco_lifestage_patch.R`.

### Claude's Discretion
- Dev script naming and structure within `dev/`
- Exact test terms used for live adapter validation
- Order of validation checks in the script
- Whether to test OLS4 failure simulation in addition to NVS (both have tryCatch now)

### Deferred Ideas (OUT OF SCOPE)
- BioPortal adapter creation — new phase inserted after Phase 35 (before Phase 36).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROV-01 | OLS4 query adapter for UBERON and PO with `obo_id` prefix post-filtering | D-05: Add `startsWith(source_term_id, paste0(ontology, ":"))` filter after NA filter at line 544. Confirmed needed by 4 GO: prefix entries in baseline CSV. |
| PROV-02 | NVS SPARQL query adapter for BODC S11 with graceful degradation on endpoint failure | D-03/D-04: Wrap lines 457-462 in tryCatch, return `tibble::tibble()` with `cli_warn` on error. |
| PROV-03 | Scoring/ranking layer (100 exact, 90 normalized, 75 token/substring; resolved/ambiguous/unresolved status) | Already fully implemented. Validate via dev script with known terms and mock-based unit test assertions. |
| PROV-04 | BioPortal Annotator as fallback provider | DEFERRED per D-01. Mark as out-of-scope in verification output. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP adapter resilience (NVS/OLS4) | R package internal | — | Failure handling lives in the adapter functions themselves, not in calling layers |
| Ontology prefix filtering | R package internal | — | Post-filter applied inside `.eco_lifestage_query_ols4()` before results leave the adapter |
| Scoring / ranking | R package internal | — | Pure function, no I/O; `.eco_lifestage_rank_candidates()` takes a candidates tibble |
| Load gate (`devtools::load_all()`) | R package namespace | — | Verifies file parses and all internal symbols bind correctly |
| Validation script | Dev tooling (`dev/`) | — | Live network smoke test, not part of package itself |

## Standard Stack

### Core (already in DESCRIPTION Imports)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| httr2 | in Imports | HTTP requests to OLS4 and NVS SPARQL | Already used throughout package |
| cli | in Imports | `cli_warn` / `cli_abort` for user messages | Project standard for all messaging |
| dplyr | >= 1.1.4 (Imports) | Tibble filtering, mutating | All data manipulation |
| tibble | in Imports | Typed empty schemas and output shapes | Package-wide data contract |
| purrr | >= 1.0.2 (Imports) | `map_dfr` in ranking loop | Already used |
| stringr | >= 1.5.1 (Imports) | `str_detect`, `str_replace_all` in scoring | Already used |
| rlang | in Imports | `arg_match` for enum validation | Already used |
| testthat | >= 3.0.0 (Suggests) | `with_mocked_bindings` for provider mocks | Already used in test-eco_lifestage_gate.R |
| withr | in Suggests | `with_envvar` in integration tests | Already used |
| devtools | dev-only | `load_all()` for load gate | Standard R package dev tool |

No new dependencies required. [VERIFIED: DESCRIPTION]

**Version verification:** All packages confirmed present in DESCRIPTION as of 2026-04-22. [VERIFIED: DESCRIPTION file]

## Architecture Patterns

### System Architecture Diagram

```
devtools::load_all()
        |
        v
  eco_lifestage_patch.R (926 lines, 14 functions)
        |
        +-- Schema functions (3): cache / dictionary / review schema
        |
        +-- Path/IO functions (5): release_id, cache_path, baseline_path,
        |   derivation_path, read_csv
        |
        +-- Validation (2): validate_cache, cache_read / cache_write
        |
        +-- Adapters (3): query_ols4 [FIX], nvs_index [FIX], query_nvs
        |       |                |
        |       v                v
        |    OLS4 REST      NVS SPARQL
        |    (ebi.ac.uk)    (nerc.ac.uk)
        |       |                |
        |   prefix filter    tryCatch
        |   UBERON:/PO:      cli_warn on failure
        |                    empty tibble returned
        |
        +-- Scoring (3): normalize_term, score_text, token_score
        |
        +-- Ranking (1): rank_candidates --> resolved/ambiguous/unresolved
        |
        +-- Orchestration (4): resolve_term, materialize_tables,
            review_from_cache, derive_fields
                |
                v
        .eco_patch_lifestage() [main entry]
```

### Recommended Project Structure
```
R/
└── eco_lifestage_patch.R    # Fix two adapters here (lines ~440-545)
dev/
└── lifestage/
    ├── validate_lifestage.R    # Existing live-API validation script
    ├── confirm_gate.R          # Existing smoke-check script
    └── validate_35.R           # NEW: Phase 35 validation script (D-07/D-08)
tests/testthat/
└── test-eco_lifestage_gate.R   # Existing — leave as-is (8 tests pass)
```

### Pattern 1: NVS tryCatch + cli_warn + Empty Tibble

**What:** Wrap the entire HTTP call chain in tryCatch. On any error, emit `cli_warn` and return `tibble::tibble()`.
**When to use:** All provider adapter functions that make live HTTP calls.

**Current code (lines 457-462) — BEFORE:**
```r
payload <- httr2::request("https://vocab.nerc.ac.uk/sparql/sparql") |>
  httr2::req_body_form(query = query) |>
  httr2::req_headers(Accept = "application/sparql-results+json") |>
  httr2::req_perform() |>
  httr2::resp_body_string() |>
  jsonlite::fromJSON(simplifyDataFrame = TRUE)

bindings <- payload$results$bindings
if (is.null(bindings) || nrow(bindings) == 0) {
  cli::cli_abort("NVS S11 lookup returned no concepts.")
}
```

**AFTER:**
```r
payload <- tryCatch(
  {
    httr2::request("https://vocab.nerc.ac.uk/sparql/sparql") |>
      httr2::req_body_form(query = query) |>
      httr2::req_headers(Accept = "application/sparql-results+json") |>
      httr2::req_perform() |>
      httr2::resp_body_string() |>
      jsonlite::fromJSON(simplifyDataFrame = TRUE)
  },
  error = function(e) {
    cli::cli_warn(c(
      "NVS S11 SPARQL endpoint unreachable.",
      "i" = "NVS candidates will be skipped for this resolution run.",
      "x" = conditionMessage(e)
    ))
    NULL
  }
)

if (is.null(payload)) {
  return(tibble::tibble())
}

bindings <- payload$results$bindings
if (is.null(bindings) || nrow(bindings) == 0) {
  cli::cli_warn("NVS S11 lookup returned no concepts.")
  return(tibble::tibble())
}
```
[ASSUMED] — exact warning message text is discretionary per D-07.

### Pattern 2: OLS4 tryCatch (D-06) — same structure

Wrap lines 501-509 (`httr2::request(...)` through `jsonlite::fromJSON(...)`) in the same tryCatch pattern. On error: `cli_warn("OLS4 endpoint unreachable for {ontology}. Skipping.")`, return `tibble::tibble()`.

### Pattern 3: OLS4 Prefix Post-Filter (D-05)

**What:** After the existing `dplyr::filter(!is.na(source_term_id), !is.na(source_term_label))` at line 544, add a second filter that enforces the expected ontology prefix.

**Current final filter (line 544):**
```r
dplyr::filter(!is.na(.data$source_term_id), !is.na(.data$source_term_label))
```

**AFTER:**
```r
dplyr::filter(
  !is.na(.data$source_term_id),
  !is.na(.data$source_term_label),
  startsWith(.data$source_term_id, paste0(toupper(ontology), ":"))
)
```
[VERIFIED: baseline CSV — 4 GO: prefix entries confirmed cross-ontology contamination]

**Effect on existing baseline CSV:** The 4 GO: prefix rows (`GO:0040007`, `GO:0007565`) in `lifestage_baseline.csv` will no longer be produced by live queries. The baseline CSV is already committed; live re-resolution with the fix will move those terms to unresolved/ambiguous status. This is correct behavior — the baseline was produced before the fix existed.

### Pattern 4: NVS Failure Simulation in dev script (D-08)

```r
# Temporarily override NVS URL to simulate unreachable endpoint
local({
  original_index <- .ComptoxREnv$eco_lifestage_nvs_index
  .ComptoxREnv$eco_lifestage_nvs_index <- NULL  # Clear cache

  # Monkey-patch: use with_mocked_bindings or override httr2::request
  # Simplest: override the internal function temporarily
  result <- testthat::with_mocked_bindings(
    .eco_lifestage_nvs_index = function(refresh = FALSE) {
      cli::cli_warn("NVS S11 SPARQL endpoint unreachable. [SIMULATED]")
      tibble::tibble()
    },
    .package = "ComptoxR",
    .eco_lifestage_query_nvs("Adult")
  )
  # Restore
  .ComptoxREnv$eco_lifestage_nvs_index <- original_index
  result
})
```
[ASSUMED] — exact simulation approach is discretionary per D-07.

Note: `with_mocked_bindings` is testthat-specific. For a plain dev script, override the NVS URL directly or use `mockery::stub()`. The simplest approach for `dev/` is to temporarily set an invalid URL via a local wrapper and verify `cli_warn` fires.

### Anti-Patterns to Avoid

- **Touching `test-eco_lifestage_gate.R`:** All 8 tests pass. The context says leave as-is.
- **Fixing the baseline CSV:** The 4 GO: rows in the CSV are historical artifacts. Do not rewrite the CSV — the fix goes in the adapter code. Live re-resolution will naturally produce different results.
- **Using `cli_abort` in adapter HTTP calls:** This kills the entire pipeline when one provider is down. All HTTP failures must use `cli_warn` + empty tibble return.
- **Caching a NULL/empty NVS index:** The `tryCatch` returns early before the `cli_env$eco_lifestage_nvs_index <- index` assignment, so no stale empty index is cached. Verify this is true in the fix.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP error handling | Custom condition classes | `tryCatch(..., error = function(e) ...)` wrapping httr2 pipeline | httr2 already raises standard R conditions on HTTP failure |
| Function mocking in dev script | Modifying global state | `testthat::with_mocked_bindings()` or `mockery::stub()` | Scoped — restores automatically |
| URL override for simulation | Env var hacks | `with_mocked_bindings(.eco_lifestage_nvs_index = ...)` | Cleanest scope for a dev script that sources the package file directly |

## Common Pitfalls

### Pitfall 1: Caching Empty NVS Index on Failure
**What goes wrong:** After the tryCatch fires and returns `tibble::tibble()`, if the return happens after the `cli_env$eco_lifestage_nvs_index <- index` line, subsequent calls use a cached empty tibble instead of retrying.
**Why it happens:** The cache assignment is at the bottom of the function. An early `return(tibble::tibble())` before it is correct behavior.
**How to avoid:** Place the `return(tibble::tibble())` inside the `tryCatch` error handler and in the `if (is.null(payload))` guard — both before the index construction and cache assignment.
**Warning signs:** Second call to `.eco_lifestage_nvs_index()` returns empty tibble without a warning.

### Pitfall 2: OLS4 Prefix Filter Uses Wrong Case
**What goes wrong:** `startsWith(source_term_id, "uberon:")` (lowercase) misses `UBERON:0000069` (uppercase).
**Why it happens:** OLS4 returns IDs in uppercase (`UBERON:`, `PO:`). The `ontology` variable is uppercased via `toupper(ontology)` but easy to miss.
**How to avoid:** Use `paste0(toupper(ontology), ":")` not `paste0(tolower(ontology), ":")`.
**Warning signs:** Filter removes all UBERON/PO rows.

### Pitfall 3: dev/ Script Sources eco_lifestage_patch.R but Not eco_connection.R
**What goes wrong:** `validate_lifestage.R` already sources `R/eco_connection.R` before `R/eco_lifestage_patch.R`. The new Phase 35 validation script must do the same if it calls `.ComptoxREnv`-dependent functions.
**Why it happens:** `.ComptoxREnv` guard at line 3-5 of `eco_lifestage_patch.R` creates the env if absent, but other functions in `eco_connection.R` may be needed.
**How to avoid:** Source both files in order, or use `devtools::load_all()` at the top of the dev script instead of manual sourcing.

### Pitfall 4: `devtools::load_all()` vcr Warning Treated as Error
**What goes wrong:** `load_all()` emits "package 'vcr' was built under R version 4.5.2" — this is a warning from vcr, not from `eco_lifestage_patch.R`.
**Why it happens:** vcr in Suggests was built under a slightly different R version.
**How to avoid:** The success criterion (D-09) is specifically "no errors or warnings attributable to `eco_lifestage_patch.R`". The vcr warning is not attributable to this file — document the distinction in the verification report.

### Pitfall 5: Scoring Status Logic Edge Case
**What goes wrong:** `resolved` requires `top_score >= 90 && sum(ranked$candidate_score == top_score) == 1`. A tie at score 90 between two candidates yields "ambiguous", not "resolved". This is correct behavior but easy to misread.
**Why it happens:** The logic at line 644. A score-75-only term with no 90+ match goes to "unresolved" (no_candidate_ge75). A score-90 tie goes to "ambiguous". Only a unique top score >= 90 yields "resolved".
**How to avoid:** Validation script should test: (a) single exact match → resolved, (b) two equal-score 90 candidates → ambiguous, (c) no match >= 75 → unresolved.

## Code Examples

### Scoring Tier Quick Reference
```r
# Source: R/eco_lifestage_patch.R lines 422-437, 644
# Score 100: exact after strict normalization (tolower + trim + collapse whitespace)
# Score 90: exact after loose normalization (+ depunct + deplural)
# Score 75: boundary_match or token_match
# Score 0: no match

# Status assignment (line 644):
resolved <- top_score >= 90 && sum(ranked$candidate_score == top_score) == 1
status <- if (resolved) "resolved" else "ambiguous"
# "unresolved" only when no candidates score >= 75
```

### Schema Column Counts (verified from source)
```r
# Source: R/eco_lifestage_patch.R lines 8-58
# cache schema: 13 columns
# dictionary schema: 13 columns (different set)
# review schema: 9 columns
```

### dev/ Validation Script Structure (Phase 35 new artifact)
```r
# Pattern from existing dev/lifestage/validate_lifestage.R
# New script: dev/lifestage/validate_35.R
suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

# 1. Load gate (already done by load_all above)

# 2. Schema function outputs
cache_schema <- .eco_lifestage_cache_schema()
stopifnot(ncol(cache_schema) == 13)

# 3. Scoring tiers
score_adult <- .eco_lifestage_score_text("Adult", "adult")
stopifnot(score_adult$score == 100)

# 4. Live OLS4 (no tryCatch needed — function now handles internally)
ols4_adult <- .eco_lifestage_query_ols4("adult", "UBERON")
# Verify all source_term_id values start with "UBERON:"
stopifnot(all(startsWith(ols4_adult$source_term_id, "UBERON:")))

# 5. NVS failure simulation
# ... (see Pattern 4 above)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `cli_abort` on NVS HTTP failure | `cli_warn` + empty tibble (after Phase 35 fix) | Phase 35 | Single provider outage no longer kills pipeline |
| OLS4 returns cross-ontology GO: terms | Post-filter by obo_id prefix (after Phase 35 fix) | Phase 35 | Prevents GO: terms from being resolved as UBERON/PO |

**Deprecated/outdated:**
- The `cli_abort("NVS S11 lookup returned no concepts.")` call at line 466 — replace with `cli_warn` + empty tibble return.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NVS failure simulation in dev script uses `with_mocked_bindings` from testthat | Pattern 4 | If dev script does not use testthat, must use mockery::stub() or direct URL override instead |
| A2 | The 4 GO: prefix entries in baseline CSV do not need manual correction | Pitfall section | If user wants baseline corrected, that is a separate task outside Phase 35 scope |
| A3 | `devtools::load_all()` vcr warning is not attributable to eco_lifestage_patch.R | Pitfall 4 | If vcr warning causes CI failure, must investigate separately |

## Open Questions

1. **OLS4 failure simulation (D-07 discretion area)**
   - What we know: D-06 adds tryCatch to OLS4. D-07 says "whether to test OLS4 failure simulation in addition to NVS" is at Claude's discretion.
   - What's unclear: User did not specify. Both adapters now have tryCatch.
   - Recommendation: Test both failure simulations in the dev script — validates the D-06 fix and takes minimal extra work.

2. **GO: prefix baseline rows and derivation coverage**
   - What we know: 4 GO: prefix entries exist in baseline (Exponential growth, Lag growth, Stationary growth, Gestation). Gestation (GO:0007565) has score=100 exact match.
   - What's unclear: Are those 4 terms in the derivation CSV? If yes, they have harmonized mappings that won't apply after the prefix fix removes them.
   - Recommendation: Check derivation CSV for GO: term IDs during planning. If present, note that live re-resolution of those terms will now produce unresolved/ambiguous until a different provider resolves them.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R | All | ✓ | 4.5.1 | — |
| devtools | Load gate (D-09) | ✓ | installed | — |
| httr2 | OLS4/NVS adapters | ✓ | in Imports | — |
| OLS4 REST API (ebi.ac.uk) | Live adapter validation | ✓ (assumed) | current | Skip live step, use mocks |
| NVS SPARQL (nerc.ac.uk) | Live adapter validation | ✓ (assumed) | current | Skip live step, mock already covers failure |
| testthat | `with_mocked_bindings` in dev script | ✓ | >= 3.0.0 in Suggests | Use mockery::stub() |

[ASSUMED] — OLS4 and NVS availability at test time not verified in this session.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat >= 3.0.0 |
| Config file | tests/testthat.R |
| Quick run command | `devtools::test(filter = "eco_lifestage_gate")` |
| Full suite command | `devtools::test()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROV-01 | OLS4 returns only UBERON:/PO: prefixed IDs | unit (mock) | `devtools::test(filter = "eco_lifestage_gate")` | ✅ existing (adapter output checked in live-refresh test) |
| PROV-01 | OLS4 prefix filter verified by function body read or live query | smoke | `Rscript dev/lifestage/validate_35.R` | ❌ Wave 0 — new script |
| PROV-02 | NVS failure emits cli_warn and returns empty tibble | unit (mock) | `devtools::test(filter = "eco_lifestage_gate")` | ❌ Wave 0 — new test case needed |
| PROV-02 | NVS failure simulation in dev script | smoke | `Rscript dev/lifestage/validate_35.R` | ❌ Wave 0 — new script |
| PROV-03 | score_text returns 100/90/75 tiers correctly | unit (pure function) | `devtools::test(filter = "eco_lifestage_gate")` | ✅ covered implicitly by existing tests |
| PROV-03 | rank_candidates assigns resolved/ambiguous/unresolved | unit (mock) | `devtools::test(filter = "eco_lifestage_gate")` | ✅ covered by existing 8 tests |

### Sampling Rate
- **Per task commit:** `devtools::test(filter = "eco_lifestage_gate")`
- **Per wave merge:** `devtools::test()`
- **Phase gate:** Full suite green + `validate_35.R` passes before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] New test case in `test-eco_lifestage_gate.R` covering PROV-02: NVS failure → `cli_warn` + empty tibble. Use `with_mocked_bindings` to mock `.eco_lifestage_nvs_index` returning empty tibble after a `cli_warn`, confirm `.eco_lifestage_query_nvs()` returns empty tibble without error.
- [ ] `dev/lifestage/validate_35.R` — Phase 35 validation script covering all 14 functions, scoring tier assertions, and NVS/OLS4 failure simulation.

## Security Domain

This phase involves no authentication, no user-facing input, no secrets, and no data persistence beyond local filesystem CSV caching. HTTP calls are read-only GET/POST to public ontology APIs. No ASVS categories apply.

## Sources

### Primary (HIGH confidence)
- `R/eco_lifestage_patch.R` — Direct code inspection, 926 lines, all 14 functions read
- `inst/extdata/ecotox/lifestage_baseline.csv` — Direct inspection, 139 data rows, 4 GO: prefix entries confirmed
- `inst/extdata/ecotox/lifestage_derivation.csv` — Direct inspection, 47 data rows
- `tests/testthat/test-eco_lifestage_gate.R` — Direct inspection, 8 tests all passing
- `DESCRIPTION` — Confirmed all required packages in Imports/Suggests
- `.planning/phases/35-shared-helper-layer-validation/35-CONTEXT.md` — Locked decisions D-01 through D-09

### Secondary (MEDIUM confidence)
- `dev/lifestage/validate_lifestage.R` — Existing validation script pattern for new script design
- Test run output — Confirmed 8/8 tests pass with `devtools::load_all()` + `vcr` warning is not from eco_lifestage_patch.R

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in DESCRIPTION
- Architecture: HIGH — full source read, no guessing
- Pitfalls: HIGH — GO: contamination confirmed in baseline CSV, NVS abort confirmed at line 466
- Validation approach: HIGH — existing test infrastructure directly applicable

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (OLS4/NVS API stability is high; scoring logic is local)
