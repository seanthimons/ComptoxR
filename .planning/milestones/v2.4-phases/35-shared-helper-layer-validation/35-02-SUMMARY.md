---
phase: 35-shared-helper-layer-validation
plan: "02"
subsystem: eco_lifestage_patch
tags: [validation, dev-script, scoring, ontology, resilience, ecotox]
requirements: [PROV-01, PROV-02, PROV-03, PROV-04]

dependency_graph:
  requires:
    - 35-01 (NVS tryCatch resilience, OLS4 prefix post-filter, PROV-02 unit test)
  provides:
    - Phase 35 comprehensive validation script (dev/lifestage/validate_35.R)
    - PROV-01 live smoke: OLS4 returns only UBERON: prefixed IDs (25/25 checked)
    - PROV-02 sim: NVS failure -> empty tibble + cli_warn, no abort
    - PROV-03 validation: exact=100, normalized=90, token=75 tier assertions
    - PROV-04 deferred: documented per D-01, not implemented
  affects:
    - dev/lifestage/validate_35.R (new file)

tech_stack:
  added: []
  patterns:
    - devtools::load_all() as D-09 load gate (replaces manual source())
    - testthat::with_mocked_bindings for adapter failure simulation in dev scripts
    - tryCatch wrapper around with_mocked_bindings for error-vs-warning discrimination

key_files:
  created:
    - dev/lifestage/validate_35.R

decisions:
  - NVS mock must return typed-empty tibble (8 columns matching NVS index schema) not zero-column tibble::tibble() — .eco_lifestage_query_nvs() calls dplyr::filter on named columns
  - OLS4 failure simulation mocks .eco_lifestage_query_ols4 at function level (not httr2::req_perform) — cleaner, avoids namespace crossing; consistent with NVS approach
  - rank_candidates with "adult" vs "post-juvenile adult stage" returns "ambiguous" not "resolved" — score is 75 (boundary_match), not 90+, so correct behavior confirmed
  - vcr warning ("package 'vcr' was built under R version 4.5.2") during load_all() is not attributable to eco_lifestage_patch.R per Pitfall 4 — documented and ignored

metrics:
  duration_minutes: 15
  completed_date: "2026-04-22"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 0
  files_created: 1
---

# Phase 35 Plan 02: Shared Helper Layer Validation — Validation Script Summary

**One-liner:** Comprehensive dev validation script exercising all 14 eco_lifestage_patch.R functions with scoring tier assertions, adapter failure simulation, and live OLS4 prefix verification.

## What Was Built

One new dev script: `dev/lifestage/validate_35.R` — 227 lines, 8 sections.

**Section 1 — Schema Functions (3 functions):**
Asserts `ncol()` == 13/13/9 for cache/dictionary/review schemas. Confirms D-09 load gate works: `devtools::load_all()` completes without errors attributable to `eco_lifestage_patch.R`.

**Section 2 — Path/IO Functions (5 functions):**
Verifies `baseline_path` and `derivation_path` point to existing files. Loads both CSVs via `.eco_lifestage_read_csv()` (139 and 47 rows respectively). Verifies `cache_path("test_release")` returns a non-empty path string. Documents `.eco_lifestage_release_id()` skip (requires live DuckDB connection).

**Section 3 — Scoring Functions (PROV-03):**
- `normalize_term("  Adult ", "strict")` -> `"adult"` (trim + tolower)
- `normalize_term("Adults.", "loose")` -> `"adult"` (depunct + deplural)
- `score_text("adult", "adult")` -> `score=100` (exact_normalized_label)
- `score_text("Adults.", "adult")` -> `score=90` (punctuation_plural_normalized_label)
- `token_score("adult male", "adult")` -> `score=75` (boundary_match — "adult" detected at start of "adult male")

**Section 4 — Ranking (PROV-03):**
- Single candidate ("post-juvenile adult stage") for term "adult" -> `ambiguous` (score=75, not >=90)
- No candidates for "Xylophage" -> `unresolved`, `reason="no_provider_candidates"`

**Section 5 — NVS Failure Simulation (D-08, PROV-02):**
`with_mocked_bindings` replaces `.eco_lifestage_nvs_index()` with a function that emits `cli_warn` and returns a typed-empty tibble (8 columns matching NVS index schema). `.eco_lifestage_query_nvs("Adult")` returns empty tibble without error. Wrapped in `tryCatch` to catch any unexpected abort.

**Section 6 — OLS4 Failure Simulation (D-06):**
`with_mocked_bindings` replaces `.eco_lifestage_query_ols4()` with a function that emits `cli_warn` and returns `tibble::tibble()`. Calls both UBERON and PO variants via `dplyr::bind_rows()`. Combined result is empty tibble without error.

**Section 7 — Live OLS4 Prefix Filter (PROV-01):**
Live call to `https://www.ebi.ac.uk/ols4/api/search` for "adult" in UBERON ontology. All 25 returned rows have `source_term_id` starting with `"UBERON:"`. Zero GO: prefix contamination confirmed — the D-05 prefix post-filter from Plan 01 is working correctly.

**Section 8 — PROV-04 Deferred Notice:**
Documents that BioPortal adapter does not exist and is deferred to a new phase per D-01.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 15c32d0 | feat(35-02): create Phase 35 validation script for all 14 helper functions |

## Verification Results

- `Rscript dev/lifestage/validate_35.R` exits 0: confirmed
- "All checks passed" printed: confirmed
- "cache_schema: 13 columns", "dictionary_schema: 13 columns", "review_schema: 9 columns": confirmed
- "score_text exact: 100", "score_text normalized: 90", "token_score partial: 75": confirmed
- "NVS failure: empty tibble returned, no abort": confirmed
- "OLS4 failure: empty tibble returned, no abort": confirmed
- "OLS4 prefix filter: all 25 row(s) have UBERON: prefix": confirmed
- "PROV-04 DEFERRED per D-01": confirmed
- `air format dev/lifestage/validate_35.R`: no changes
- `jarl check dev/lifestage/validate_35.R`: "All checks passed!"

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Pattern] NVS mock must use typed-empty tibble not zero-column tibble**
- **Found during:** Task 1 — pre-emptive application of Plan 01 lesson
- **Issue:** Plan 01's deviation log confirmed that mocking `.eco_lifestage_nvs_index()` to return `tibble::tibble()` (zero columns) causes `.eco_lifestage_query_nvs()` to fail with "Column not found" when calling `dplyr::filter()` on `source_term_label` and `candidate_aliases`.
- **Fix:** Applied the typed-empty tibble pattern from Plan 01 Summary (8-column schema: source_provider, source_ontology, source_term_id, source_term_label, source_term_definition, source_release, source_match_method, candidate_aliases).
- **Files modified:** dev/lifestage/validate_35.R
- **Commit:** 15c32d0 (pre-emptive, not a post-hoc fix)

## Known Stubs

None. The validation script is fully wired — no placeholder values, no TODO markers, no hardcoded empty results passed to assertions.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The validation script:
- Is in `dev/` and not shipped with the package
- Makes read-only HTTP GET to public OLS4 API (ebi.ac.uk) — same endpoint as the package adapter
- No secrets, credentials, or user data involved

Threat mitigations from T-35-05 and T-35-06 confirmed working:
- T-35-05 (OLS4 network unavailability): Section 7 wraps live call in tryCatch; unavailability prints info and skips
- T-35-06 (dev script information disclosure): Script uses only public APIs, dev/ is not installed

## Self-Check: PASSED

Files exist:
- FOUND: dev/lifestage/validate_35.R (227 lines)
- FOUND: .planning/phases/35-shared-helper-layer-validation/35-02-SUMMARY.md

Commits exist:
- FOUND: 15c32d0 (Task 1 — validation script creation)
