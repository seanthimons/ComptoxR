---
phase: 32-build-pipeline-integration
plan: 01
status: complete
started: 2025-07-25
completed: 2025-07-25
tasks_completed: 2
tasks_total: 2
requirements_satisfied: [GATE-01, GATE-02, GATE-03, INTG-02]
key-files:
  modified:
    - inst/ecotox/ecotox_build.R
    - data-raw/ecotox.R
---

## What Was Built

Replaced section 16 of both ECOTOX build scripts (`inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R`) with the validated Phase 31 lifestage harmonization system:

1. **Inline keyword classifier** (`.classify_lifestage_keywords()`) — 7-rule priority-ordered regex classifier producing 5-column tibbles with `keyword_fallback` classification source
2. **139-row 5-column dictionary tribble** — `org_lifestage`, `harmonized_life_stage`, `ontology_id`, `reproductive_stage`, `classification_source` — replacing the old 137-row 2-column tribble
3. **Two-tier build gate** — queries `lifestage_codes` for unmapped terms, runs keyword classifier on gaps, aborts (`cli_abort`) on truly unknown terms, warns and quarantines keyword-classifiable terms to `lifestage_review` table

## Key Decisions

- Classifier defined inline in build script (not in `R/eco_functions.R`) per D-01/D-03
- Both `dbWriteTable` calls use `overwrite = TRUE` per D-06/D-07
- `#fmt: off/on` guards replace old `#fmt: table` per plan requirements
- Variable renamed from `life_stage_new` to `life_stage` to match existing downstream references

## Verification

- Both files contain `.classify_lifestage_keywords` function definition
- Both files have `overwrite = TRUE` on dictionary and review table writes
- `cli_abort` gate present for truly unknown lifestages
- `cli_alert_warning` + review table write for keyword-classifiable terms
- Section 16 is byte-for-byte identical between both build scripts (verified via diff)
- No `#fmt: table` in section 16 (uses `#fmt: off/on` instead)
- Section 17 boundary intact in both files
- `air format` and `jarl check` pass on both files

## Self-Check: PASSED

All acceptance criteria from plan 32-01 verified:
- [x] `.classify_lifestage_keywords <- function(descriptions)` present in both files
- [x] `dbWriteTable(eco_con, "lifestage_dictionary", life_stage, overwrite = TRUE)` present
- [x] `dbWriteTable(eco_con, "lifestage_review", keyword_mapped, overwrite = TRUE)` present
- [x] `cli::cli_abort(c(` present in section 16
- [x] `setdiff(db_lifestages, life_stage$org_lifestage)` present
- [x] Tribble contains `~ontology_id`, `~reproductive_stage`, `~classification_source`
- [x] `#fmt: off` before rules and life_stage tribbles
- [x] No `#fmt: table` in section 16
- [x] Variable named `life_stage` (not `life_stage_new`)
- [x] Section 17 header preserved
- [x] `air format` exits 0 for both files
- [x] `jarl check` reports no errors for both files
- [x] Section 16 diff between both files produces zero output
