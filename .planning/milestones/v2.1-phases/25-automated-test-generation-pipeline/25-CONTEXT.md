# Phase 25: Automated Test Generation Pipeline - Context

**Gathered:** 2026-02-27
**Status:** Ready for planning

<domain>
## Phase Boundary

CI-integrated pipeline that detects exported API-calling functions lacking substantive tests, generates test files using the Phase 23 test generator, and reports coverage — chained into the existing schema-check workflow. Schemas → stubs → docs → detect gaps → generate tests → coverage → automated PR.

</domain>

<decisions>
## Implementation Decisions

### Gap detection logic
- A "gap" is an exported function that calls `generic_request()` or `generic_chemi_request()` and either has no test file or has a test file without real `test_that()` blocks
- Detection scans function bodies for calls to any `generic_*` function in `z_generic_request.R`
- Non-API utility functions are excluded from automated gap detection (they need different test approaches)
- Test files with no actual assertions (empty skeletons) still count as gaps
- Output: structured report file (JSON or CSV) to `dev/reports/` with function name, file path, and gap reason; also prints summary to stdout

### CI workflow design
- Test generation steps added directly to existing `schema-check.yml` (not a separate workflow)
- Pipeline order: schemas → stubs → docs → **detect gaps → generate tests** → coverage → PR
- Triggers: auto on stub file changes + manual `workflow_dispatch`
- Generated tests committed to the same automated branch as schemas/stubs
- PR body extended with a "Test Gaps" report section showing tests generated and remaining gaps
- Follows existing pattern: single PR bundles schemas + stubs + docs + tests + coverage

### Overwrite protection
- Auto-maintained manifest at `dev/test_manifest.json` tracks each test file as "generated" or "protected"
- Generator automatically adds entries when creating new test files
- Developers manually mark files as "protected" when they customize them
- Protected files are never overwritten by the generator
- Protected files whose underlying function signature has changed are flagged as warnings in the gap report (staleness detection)
- Manifest tracks status only (no signature hashes or dates) — simple and low maintenance

### Pipeline integration
- Separate standalone scripts: `dev/detect_test_gaps.R` and `dev/generate_tests.R`
- Both work independently when run locally (outside CI)
- CI chains them as separate steps (no wrapper orchestrator script)
- Test generation outputs GITHUB_OUTPUT variables matching the stub generator pattern (tests_generated, tests_skipped, gaps_remaining) for PR body reporting

### Claude's Discretion
- Internal report format details (JSON vs CSV)
- Exact staleness detection heuristic for protected files
- How to handle edge cases (functions with multiple generic_request calls, internal helpers that happen to use generic_request)
- PR body formatting and section ordering

</decisions>

<specifics>
## Specific Ideas

- Chain to schema workflow: "If it's possible to chain GHAs; chain it to the schema change so that way we get new schemas + functions + tests" — achieved by adding steps to schema-check.yml
- Match existing stub generator pattern for GITHUB_OUTPUT variables
- Gap report in PR body alongside existing coverage metrics table
- Existing `dev/generate_tests.R` already exists from Phase 23 — extend it rather than rewrite

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 25-automated-test-generation-pipeline*
*Context gathered: 2026-02-27*
