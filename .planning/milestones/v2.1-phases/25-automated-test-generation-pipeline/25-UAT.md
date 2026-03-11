---
status: complete
phase: 25-automated-test-generation-pipeline
source: 25-01-SUMMARY.md, 25-02-SUMMARY.md, 25-03-SUMMARY.md
started: 2026-03-01T12:00:00Z
updated: 2026-03-01T12:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Gap detection script runs successfully
expected: Running `Rscript dev/detect_test_gaps.R` completes without errors, scans R/ directory for API wrapper files, and prints a CLI summary showing total gaps found.
result: pass

### 2. AST-based API wrapper detection distinguishes API functions from utilities
expected: The script correctly identifies ct_hazard as an API wrapper (TRUE) and util_cas as a non-API function (FALSE), using parse()+all.names() instead of regex.
result: pass

### 3. Manifest system tracks test file status
expected: `dev/test_manifest.json` exists with version "1.0", contains file entries with "status" field ("generated" or "protected"), and includes ISO timestamps.
result: pass

### 4. JSON gap report generated in dev/reports/
expected: After running the gap detection script, a JSON file appears in dev/reports/ with structure containing timestamp, gaps_count, gaps array, and stale_protected array.
result: pass

### 5. Test generator respects manifest protection
expected: Running `Rscript dev/generate_tests.R` skips files marked as "protected" in the manifest and only generates/overwrites files marked as "generated" or new files.
result: pass

### 6. Test generator filters to API wrappers only
expected: The generator only creates tests for functions that call generic_request/generic_chemi_request/generic_cc_request, skipping utility functions like util_cas even if they match ct_/chemi_ naming patterns.
result: issue
reported: "If there are 13 non-API files, why do they show up in the initial count (the 256)? CLI message says 'Found 256 API wrapper files' before filtering, should say 'candidate files' or similar"
severity: minor

### 7. CI workflow includes gap detection and test generation steps
expected: `.github/workflows/schema-check.yml` contains steps with ids "gaps" and "tests", positioned after documentation update and before coverage calculation. Both use continue-on-error: true.
result: pass
note: Flagged for future review when workflow actually runs

### 8. CI workflow PR body includes test metrics section
expected: The schema-check workflow's PR body template includes a "Test Gaps & Generation" section displaying gaps_count, tests_generated, tests_skipped, and gaps_remaining values.
result: pass
note: Flagged for future review when workflow actually runs

## Summary

total: 8
passed: 7
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Test generator accurately labels file counts in CLI output"
  status: failed
  reason: "User reported: CLI message says 'Found 256 API wrapper files' before AST filtering, but 13 of those are not API wrappers. Label is misleading — should say 'candidate files' or 'matching files' instead of 'API wrapper files'"
  severity: minor
  test: 6
  artifacts: []
  missing: []
