---
status: complete
phase: 36-bootstrap-data-artifacts
source: [36-01-SUMMARY.md, 36-02-SUMMARY.md]
started: 2026-04-23T16:30:00Z
updated: 2026-04-23T16:55:00Z
---

## Current Test

[testing complete]

## Tests

### 1. GO:0040007 Contamination Removed from Baseline
expected: lifestage_baseline.csv contains zero rows with GO:0040007 as a resolved ontology term. The 3 microbial growth-phase terms are marked unresolved.
result: pass

### 2. Derivation CSV Covers All Resolved Baseline Keys
expected: Running the CI cross-check test (`testthat::test_file("tests/testthat/test-eco_lifestage_data.R")`) passes all 5 tests with 0 failures. The anti-join of resolved baseline keys against derivation keys returns 0 unmatched rows.
result: pass

### 3. Derivation CSV Has 6 New Curator Rows
expected: lifestage_derivation.csv has 53 rows total. The 6 new entries (S1106, S1116, S1122, S1128, PO:0000055, PO:0009010) are all present with valid org_lifestage mappings.
result: pass

### 4. Validation Script Runs Clean
expected: Running `source("dev/lifestage/validate_36.R")` completes all 4 sections (schema baseline, schema derivation, cross-check gate, GO:0040007 contamination check) and prints "All checks passed" with no errors or warnings.
result: pass

### 5. Refresh Baseline Script Exists and Is Safe
expected: `dev/lifestage/refresh_baseline.R` exists, references `.eco_lifestage_resolve_term` for re-resolution, and writes proposals to `derivation_proposals.csv` only — never to the committed `lifestage_derivation.csv`.
result: pass

### 6. Curator README Documents Workflow
expected: `dev/lifestage/README.md` exists and documents: when to run the refresh, prerequisites, the 5-step procedure, and the rule that derivation changes must never be auto-committed.
result: pass

### 7. PO:0000055 and PO:0009010 Provisional Mappings
expected: In lifestage_derivation.csv, PO:0000055 (bud) maps to Adult with reproductive_stage=TRUE, and PO:0009010 (seed) maps to Egg/Embryo with reproductive_stage=FALSE. Curator confirms these mappings are botanically correct.
result: pass

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
