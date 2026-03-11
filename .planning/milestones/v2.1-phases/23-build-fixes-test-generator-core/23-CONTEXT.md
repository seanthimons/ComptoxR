# Phase 23: Build Fixes & Test Generator Core - Context

**Gathered:** 2026-02-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix stub syntax errors and package build issues so R CMD check passes cleanly. Rebuild the test generator to read actual function metadata and produce correct tests. Additionally, align the schema automation pipeline (schema selection + drift detection from SCHEMA_AUTOMATION_PLAN.md Items 2 & 3).

Scope includes:
- BUILD-01 through BUILD-08 (package build fixes)
- TGEN-01 through TGEN-05 (test generator core)
- Schema selection alignment (SCHEMA_AUTOMATION_PLAN Item 2)
- Parameter drift detection (SCHEMA_AUTOMATION_PLAN Item 3)

Each item must include tests.

</domain>

<decisions>
## Implementation Decisions

### Build fix ordering and strategy
- Merge the open PR first to get up-to-date schemas locally
- Fix non-generator BUILD issues first (BUILD-02 through BUILD-08) before touching the generator
- Then fix the generator pipeline itself (BUILD-01 syntax bugs + Items 2 & 3)
- Purge experimental stubs using existing scripts, then regenerate all stubs from the fixed generator
- Final R CMD check should be clean after regeneration

### License (BUILD-07)
- Use MIT + file LICENSE
- Run `usethis::use_mit_license()` to set up properly

### Schema automation pipeline (Items 2 & 3)
- Item 2: Move `select_schema_files()` to shared utility, align diff reporter and stub generator on same schema selection
- Item 3: Add `detect_parameter_drift()` as report-only (no auto-modification of existing functions)
- Both items included in Phase 23 with tests, clearly defined as separate work units
- Follow the design in SCHEMA_AUTOMATION_PLAN.md (Approach A for Item 2)

### Test generator depth
- Smoke tests + type checks: verify function runs without error, returns correct type (tibble vs list), has expected column names
- No comprehensive value assertions (too brittle with changing API responses)

### Test variants per function
- **single** — one valid input, VCR cassette recorded
- **batch** — vector of 2-3 valid inputs, VCR cassette recorded
- **error** — missing required params, pure R check, no cassette needed
- API error response variants (invalid input -> HTTP error) deferred to Phase 24 when cassettes are clean

### Test fixture value resolution
- Priority 1: Use values from roxygen `@examples` if the function has examples filled out
- Priority 2: Fall back to explicit mapping table of parameter-name-to-default-value
- Canonical fallback DTXSID: DTXSID7020182 (Bisphenol A)
- Mapping table covers: formula, SMILES, CAS, list names, AEIDs, and other parameter types
- Batch tests use 2-3 items (small enough for compact cassettes, large enough to verify batching)

### Claude's Discretion
- Exact parameter-to-value mapping table entries (beyond the canonical DTXSID)
- How to detect which stubs have manual edits vs pure generated code
- Implementation details of `detect_parameter_drift()` (parse-based vs regex-based formals extraction)
- Ordering of individual BUILD-02 through BUILD-08 fixes within the "before regeneration" group
- httr2 compatibility resolution approach (BUILD-05: update minimum version vs replace missing functions)

</decisions>

<specifics>
## Specific Ideas

- SCHEMA_AUTOMATION_PLAN.md contains detailed design for Items 2 & 3 including file locations, function signatures, and testing strategies — use it as the implementation reference
- The existing `dev/endpoint_eval/` pipeline structure should be preserved and extended (Item 2 moves `select_schema_files()` to `01_schema_resolution.R`, Item 3 adds `08_drift_detection.R`)
- Drift detection is report-only for now; auto-updating experimental stubs is a future enhancement

</specifics>

<deferred>
## Deferred Ideas

- API error response test variants (invalid input -> HTTP errors with cassettes) — Phase 24 when cassette infrastructure is clean
- Auto-updating experimental lifecycle stubs based on drift detection — future enhancement after drift reporting is proven
- Scheduled/automated cassette re-recording — Phase 24

</deferred>

---

*Phase: 23-build-fixes-test-generator-core*
*Context gathered: 2026-02-27*
