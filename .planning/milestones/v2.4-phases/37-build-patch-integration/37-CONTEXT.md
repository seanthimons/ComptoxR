# Phase 37: Build & Patch Integration - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the ECOTOX full-build path and in-place patch path both produce the same correct `lifestage_dictionary` and `lifestage_review` tables using the shared source-backed lifestage helper layer. This phase validates and tightens integration wiring: section 16 sync across both build scripts, internal patch orchestration, deterministic refresh behavior, Windows-safe DuckDB write connection retry, and patch metadata in `_metadata`.

This phase is not a new ontology expansion, semantic adjudication, or end-user editing phase. Lifestage record edits remain CSV-based policy/data changes; R code owns behavior and orchestration only.

</domain>

<decisions>
## Implementation Decisions

### Shared build and patch orchestration
- **D-01:** `.eco_patch_lifestage()` is the single internal orchestration function for patching installed ECOTOX lifestage tables.
- **D-02:** The same internal path owns the "resolve any new lifestages, then repatch" workflow through live refresh behavior.
- **D-03:** Patch/build orchestration must live in package code under `R/` so it is available to installed ECOTOX build and patch workflows, not only development scripts.
- **D-04:** `.eco_patch_lifestage()` remains internal in this phase. It does not need to be exported as an ordinary user-facing API.
- **D-05:** End-user or maintainer record changes remain CSV-only. Users should not edit R build code to change lifestage records.

### Build-script section 16 shape
- **D-06:** Both `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` should keep a thin section 16 wrapper.
- **D-07:** The thin wrapper should extract distinct `lifestage_codes.description`, determine `ecotox_release`, call shared internal materialization logic, and write `lifestage_dictionary` and `lifestage_review`.
- **D-08:** Do not move all section 16 behavior into duplicated inline blocks. Shared resolver/materialization behavior belongs in package internals.
- **D-09:** Regression protection for section 16 should remain a character-identical wrapper test. This directly guards drift between the repo build script and installed build action.

### Refresh mode semantics
- **D-10:** `refresh = "auto"` should use a matching committed baseline when no matching user cache exists.
- **D-11:** `refresh = "auto"` must not make live provider calls as normal behavior. Cold-start patching should be deterministic and local-artifact based.
- **D-12:** Live provider resolution should happen only with explicit `refresh = "live"` or `force = TRUE`.
- **D-13:** `refresh = "baseline"` must abort on ECOTOX release mismatch. No cross-release baseline patching.
- **D-14:** `force = TRUE` means force live lookup. Force bypasses cache/baseline and resolves through live providers regardless of the original refresh mode.
- **D-15:** Tests for `force = TRUE` should mock provider calls, and user-facing messages/docs should make clear that `force` can use the network.

### Windows DuckDB retry behavior
- **D-16:** The Windows-safe retry boundary is the close-then-connect sequence around opening the DuckDB file read-write.
- **D-17:** Each attempt should call `.eco_close_con()`, then attempt `DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)`.
- **D-18:** Retry policy is exactly 3 attempts with 200 ms backoff between failures.
- **D-19:** Once a read-write connection succeeds, later table writes and metadata writes should not be retried by this loop. Write failures after a successful connection should surface as real patch failures.
- **D-20:** Validation should mock `DBI::dbConnect()` to fail twice and then succeed. Do not rely on flaky real DuckDB lock contention for this phase.
- **D-21:** If all three attempts fail, abort with a patch-specific message and include the last DBI error.

### Patch metadata contract
- **D-22:** After a successful patch, `_metadata` should contain these four key-value rows:
  - `lifestage_patch_applied_at`
  - `lifestage_patch_release`
  - `lifestage_patch_method`
  - `lifestage_patch_version`
- **D-23:** Each successful patch should replace prior `lifestage_patch_*` rows. `_metadata` represents latest patch state, not patch history.
- **D-24:** Metadata validation should require all four keys and verify non-empty values.
- **D-25:** Metadata validation should confirm `lifestage_patch_method` equals the actual refresh mode used, `lifestage_patch_release` equals the installed DB release, and `lifestage_patch_version` equals the current package version.

### Agent's Discretion
- Exact helper names and extraction boundaries, provided both build scripts remain thin and character-identical in section 16.
- Exact test organization between existing `tests/testthat/test-eco_lifestage_gate.R` and a Phase 37 validation script.
- Exact wording for patch messages, provided release mismatch, forced live lookup, and final write-open failure are clear.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` - Phase 37 goal, dependency on Phase 36.2, and success criteria for section 16 sync, refresh modes, Windows retry, and metadata.
- `.planning/REQUIREMENTS.md` - INTG-01 through INTG-04 requirements.
- `.planning/PROJECT.md` - v2.4 milestone goal and source-backed lifestage scope.
- `.planning/STATE.md` - Current project position: Phase 37 ready to discuss after Phase 36.2.

### Prior Phase Context
- `.planning/phases/36.2-dictionary-rebuild-validation/36.2-CONTEXT.md` - Source-backed semantic adjudication checkpoint; establishes that Phase 37 should not reopen ontology expansion or derivation policy.
- `.planning/phases/36-bootstrap-data-artifacts/36-CONTEXT.md` - Baseline/derivation CSV policy, no regex backstop, and manual refresh expectations.
- `.planning/phases/35-shared-helper-layer-validation/35-CONTEXT.md` - Shared helper validation, OLS4/NVS/BioPortal helper context, and provider resilience expectations.

### Product Code and Tests
- `R/eco_lifestage_patch.R` - Internal helper layer, `.eco_lifestage_materialize_tables()`, `.eco_patch_lifestage()`, refresh mode handling, patch metadata writes, and current write-connection behavior.
- `data-raw/ecotox.R` - Repo-side ECOTOX build script; section 16 must remain synced with installed build script.
- `inst/ecotox/ecotox_build.R` - Installed ECOTOX build action; section 16 must remain synced with repo build script.
- `tests/testthat/test-eco_lifestage_gate.R` - Existing patch-path tests, refresh mode tests, metadata test, runtime read test, and section 16 identity test.
- `inst/extdata/ecotox/lifestage_baseline.csv` - Committed baseline used for deterministic `auto` and `baseline` patching.
- `inst/extdata/ecotox/lifestage_derivation.csv` - Curated derivation map used when materializing `lifestage_dictionary`.

### Design and Handoff
- `LIFESTAGE_HARMONIZATION_PLAN2.md` - Original design for in-place patch support, refresh modes, patch metadata keys, and section 16 replacement.
- `HANDOFF.md` - Current lifestage routing handoff; warns against ontology expansion as the next reflex and lists relevant lifestage files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.eco_lifestage_materialize_tables()` already materializes cache, dictionary, review, and `refresh_mode` from lifestage terms and release.
- `.eco_patch_lifestage()` already patches `lifestage_dictionary`, `lifestage_review`, and `_metadata` in place.
- `.eco_close_con()` is already part of the intended mitigation for stale/read ECOTOX connections before patching.
- Existing helper path resolution functions locate committed CSVs from installed package data or development paths.
- `tests/testthat/test-eco_lifestage_gate.R` already has helper fixtures for temporary DuckDB patch tests and mocked provider refresh paths.

### Established Patterns
- ECOTOX metadata uses key-value rows in `_metadata`; patch metadata should follow that shape.
- Build scripts currently duplicate section 16, and an existing test extracts section 16 blocks with a regex and expects character identity.
- Patch tests use `with_mocked_bindings()` to prevent unintended live provider calls.
- Source-backed lifestage policy/data lives in committed CSVs under `inst/extdata/ecotox/`.
- Runtime user-facing failures and warnings use `cli::cli_abort()`, `cli::cli_warn()`, and `cli::cli_alert_*()`.

### Integration Points
- Section 16 in both ECOTOX build scripts should call shared internal materialization logic while preserving a local build-wrapper shape.
- `.eco_patch_lifestage()` should be the patch entry point for installed DBs and should apply the close/connect retry loop.
- Patch metadata validation belongs near existing patch tests in `tests/testthat/test-eco_lifestage_gate.R`.
- A Phase 37 validation script may be added under `dev/lifestage/` if useful for human-readable verification, but the durable gates should live in testthat.

</code_context>

<specifics>
## Specific Ideas

- The main section 16 regression risk is drift between `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R`: different refresh mode, missing review write, different cache write behavior, different release calculation, or one path keeping stale inline code.
- The character-identity section 16 wrapper test is sufficient if the wrapper is thin. Shared behavior should be tested through materialization and patch-path tests.
- `force = TRUE` is intentionally strong: "force is force." It should hit live providers and should be tested with mocks.
- End users should not edit R helper code to change lifestage records. Editing a CSV is the record-editing mechanism.

</specifics>

<deferred>
## Deferred Ideas

- Exporting a public `.eco_patch_lifestage()`-style API remains future work (`ECOX-02`) unless a later phase deliberately changes the API boundary.
- Patch history/audit table is out of scope for Phase 37; `_metadata` should reflect latest patch only.
- Real Windows DuckDB contention/integration testing can be considered later if mocked retry validation proves insufficient.

</deferred>

---

*Phase: 37-build-patch-integration*
*Context gathered: 2026-04-28*
