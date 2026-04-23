# ECOTOX Lifestage Data Maintenance

This directory contains developer scripts for maintaining the lifestage ontology resolution data shipped with ComptoxR.

## Directory Contents

| File | Purpose |
|------|---------|
| `validate_35.R` | Phase 35 helper layer validation (historical) |
| `validate_36.R` | Phase 36 data artifact integrity check |
| `validate_lifestage.R` | General lifestage pipeline validation |
| `refresh_baseline.R` | Regenerate baseline CSV for new ECOTOX releases |
| `purge_and_rebuild.R` | Drop and rebuild lifestage tables from scratch |
| `confirm_gate.R` | Gate logic confirmation script |

## When to Run `refresh_baseline.R`

Run this script after installing a new ECOTOX release into `ecotox.duckdb`:

1. Download the new ECOTOX ASCII export from EPA
2. Rebuild the DuckDB database (via `ecotox_build.R` or the package build pipeline)
3. Run the refresh script from the project root:
   ```
   Rscript dev/lifestage/refresh_baseline.R
   ```

## Prerequisites

- **Database:** `ecotox.duckdb` must exist with the new release data.
  Location is resolved via `eco_path()` (typically `tools::R_user_dir("ComptoxR", "data")/ecotox.duckdb`).
- **Network:** OLS4 and NVS SPARQL APIs must be reachable. The script calls
  `.eco_lifestage_resolve_term()` which queries these services for ontology resolution.
- **Package loaded:** The script calls `devtools::load_all(".")` — run from the package root.

## Refresh Workflow

### Step 1: Regenerate Baseline

```
Rscript dev/lifestage/refresh_baseline.R
```

This script:
- Reads all distinct lifestage descriptions from `lifestage_codes` in the DB
- Re-resolves each term via OLS4 + NVS providers
- Writes the updated baseline to `inst/extdata/ecotox/lifestage_baseline.csv`

### Step 2: Review Derivation Proposals

If new resolved terms have `(source_ontology, source_term_id)` keys not present in
`inst/extdata/ecotox/lifestage_derivation.csv`, the script writes them to:

```
dev/lifestage/derivation_proposals.csv
```

This file contains proposed derivation rows with `harmonized_life_stage` and
`reproductive_stage` set to NA. **You must fill these in manually.**

For each proposed row:
1. Look up the `source_term_label` in the baseline CSV
2. Assign the appropriate `harmonized_life_stage` category:
   Adult, Egg/Embryo, Larva, Juvenile, Subadult, Senescent/Dormant, or Other/Unknown
3. Set `reproductive_stage` to TRUE or FALSE
4. Set `derivation_source` to `"baseline_curated_source_id"`

### Step 3: Promote Approved Rows

Copy approved rows from `dev/lifestage/derivation_proposals.csv` into
`inst/extdata/ecotox/lifestage_derivation.csv`. Maintain alphabetical sort order
by `source_ontology` then `source_term_id`.

### Step 4: Repatch the Database

After both CSVs are committed, repatch the live database:

```r
devtools::load_all(".")
.eco_patch_lifestage(refresh = "baseline")
```

This rebuilds `lifestage_dictionary` from the committed CSVs without hitting any
live API.

### Step 5: Verify

```
Rscript dev/lifestage/validate_36.R
```

Confirms schema integrity, cross-check gate, and DB completeness.

## Important Rules

- **Never auto-commit derivation rows.** The `lifestage_derivation.csv` file is
  curator-authored only. All automation writes to `derivation_proposals.csv` for review.
- **`cli_warn`, not `cli_abort`, for derivation gaps.** The refresh script warns about
  missing derivation entries but does not abort. You control the pacing of baseline
  commit vs. derivation commit.
- **The CI gate catches regressions.** `tests/testthat/test-eco_lifestage_data.R`
  runs on every `devtools::test()` and will fail if the cross-check invariant is violated.
