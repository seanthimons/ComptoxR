---
phase: 17-schema-diffing
plan: 01
subsystem: dev-tools
tags: [schema-diff, breaking-changes, ci-integration]
dependency_graph:
  requires: [openapi_to_spec from 04_openapi_parser.R]
  provides: [diff_schemas, diff_single_schema, format_diff_markdown]
  affects: [CI workflow (Plan 02)]
tech_stack:
  added: [diff engine with breaking change classification]
  patterns: [endpoint comparison, parameter diffing, markdown formatting]
key_files:
  created:
    - dev/diff_schemas.R
  modified: []
decisions: []
metrics:
  duration: 4min
  completed: 2026-02-12
---

# Phase 17 Plan 01: Schema Diffing Engine Summary

**One-liner:** Endpoint-level diff engine detecting breaking/non-breaking API changes between OpenAPI schema versions

## What Was Built

Created `dev/diff_schemas.R` with four core functions and CLI entrypoint for GitHub Actions integration:

1. **`diff_single_schema(old_path, new_path)`** - Compares two schema files at endpoint level
   - Creates endpoint keys as `"{METHOD} {route}"`
   - Detects added, removed, and modified endpoints
   - Classifies changes as breaking or non-breaking
   - Returns structured list with tibbles for each change type

2. **`diff_schemas(old_dir, new_dir, pattern)`** - Compares all schemas between two directories
   - Handles files present in only one directory (all added/removed)
   - Calls `diff_single_schema()` for files in both
   - Filters out schemas with zero changes
   - Returns list of per-schema diff results

3. **`format_diff_markdown(diff_results)`** - Produces markdown for PR bodies
   - Summary line with total counts
   - Breaking Changes table (removed endpoints, removed params, body changes)
   - Non-Breaking Changes table (added endpoints, added params, deprecations)
   - Returns "No endpoint-level changes detected" when no diffs

4. **`classify_param_change(old_params, new_params)`** - Helper for param diffing
   - Breaking: any parameter removed
   - Non-breaking: only additions
   - Returns list with `breaking` (logical) and `detail` (string)

**CLI Entrypoint:**
- Accepts command-line args: `old_dir` and `new_dir`
- Writes markdown report to `schema_diff_report.md`
- Outputs `BREAKING_COUNT=N` and `NONBREAKING_COUNT=N` to stdout for CI parsing

## Breaking Change Classification

**Breaking:**
- Removed endpoints
- Removed parameters (query, path, or body)
- Request body removed
- Request body added

**Non-Breaking:**
- Added endpoints
- Added parameters
- Endpoint deprecated

## Integration Test Results

Validated with synthetic schema modifications:
- ✓ Detected 1 added endpoint (classified as non-breaking)
- ✓ Detected 1 removed endpoint (classified as breaking)
- ✓ Detected 1 modified endpoint with param addition (classified as non-breaking)
- ✓ Markdown output contains "Breaking Changes" section
- ✓ Markdown output contains "Non-Breaking Changes" section

## Deviations from Plan

None - plan executed exactly as written.

## Dependencies

**Sources required:**
- `dev/endpoint_eval/00_config.R` - Constants (CHEMICAL_SCHEMA_PATTERNS, %||%)
- `dev/endpoint_eval/01_schema_resolution.R` - Schema parsing helpers
- `dev/endpoint_eval/06_param_parsing.R` - Parameter utilities
- `dev/endpoint_eval/04_openapi_parser.R` - openapi_to_spec()

**Required packages:**
- jsonlite (JSON parsing)
- dplyr (tibble manipulation)
- purrr (functional programming)
- tibble (data structures)
- here (path resolution)

## Next Steps

Plan 02 will integrate this diff engine into `.github/workflows/schema-check.yml` to:
1. Run diffs on PR schema changes
2. Inject markdown report into PR body
3. Block merges if breaking changes detected

## Self-Check: PASSED

**Files created:**
```
[FOUND] dev/diff_schemas.R
```

**Commits created:**
```
[FOUND] 91d6ea6 - feat(17-01): create diff_schemas.R with endpoint-level diffing
```

**Functions verified:**
- diff_schemas: TRUE
- diff_single_schema: TRUE
- format_diff_markdown: TRUE
- classify_param_change: TRUE

**Integration test:**
- All assertions passed
- Breaking/non-breaking classification correct
- Markdown formatting valid

---

*Completed: 2026-02-12 | Duration: 4 minutes*
