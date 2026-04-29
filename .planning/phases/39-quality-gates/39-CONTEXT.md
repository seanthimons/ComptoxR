# Phase 39: Quality Gates - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Provider adapters must have CI-safe mocked tests for OLS4, NVS, and BioPortal, and the release validation path must prove these tests do not hit live external APIs or require provider API keys.

This phase is a quality-gate phase, not a new provider expansion, semantic adjudication, runtime API redesign, or release-note polish phase. Phase 38 already finalized the `eco_results()` lifestage output contract.

</domain>

<decisions>
## Implementation Decisions

### Adapter Test Boundary
- **D-01:** Add direct adapter tests for `.eco_lifestage_query_ols4()`, `.eco_lifestage_nvs_index()` / `.eco_lifestage_query_nvs()`, and `.eco_lifestage_query_bioportal()` rather than only testing through `.eco_lifestage_resolve_term()` or `.eco_patch_lifestage()`.
- **D-02:** Put the new provider adapter tests in `tests/testthat/test-eco_lifestage_gate.R`, reusing the existing lifestage gate fixtures and `with_mocked_bindings()` style.
- **D-03:** Happy-path assertions should use a minimal schema contract: each adapter returns a tibble with the lifestage candidate schema and expected provider, ontology, source ID, label, and match-method fields.
- **D-04:** Include provider-specific contract checks where they matter: OLS4 prefix filtering, NVS S11/index shape, and BioPortal API-key/request handling.
- **D-05:** Do not add VCR cassettes or external fixture files for these provider tests. Use small inline mocked responses in the test file.

### Failure And Fallback Coverage
- **D-06:** For each provider, cover both a thrown/request-failure path and a valid-but-empty response path.
- **D-07:** Actual endpoint/key failures should warn and return an empty candidate tibble with the expected schema.
- **D-08:** Valid-but-empty provider responses should silently return an empty candidate tibble; "no match" is not itself a warning condition.
- **D-09:** Broader resolver fallback is planner discretion. Direct adapter failure tests are required; add one resolver-continuation smoke test only if direct tests leave QUAL-01 ambiguous.
- **D-10:** Missing `BIOPORTAL_API_KEY` coverage is planner discretion, but keyless CI safety must be enforced somewhere in the provider/offline tests.

### Offline Enforcement
- **D-11:** Use sentinel mocks so tests fail if an unexpected `httr2::req_perform()` reaches a live provider request.
- **D-12:** Passing tests should themselves prove the no-network/no-key gate, including keyless BioPortal behavior where relevant, not rely only on human instructions.
- **D-13:** The focused verification command is `devtools::test(filter = "eco_lifestage_gate")`.
- **D-14:** Inspect and tighten existing live-refresh/force patch tests if they can leak live calls to providers such as Wikidata or AGROVOC. Existing tests should remain deterministic.

### Release Documentation And Dev Scripts
- **D-15:** Drop the `NEWS.md` breaking-change gate for Phase 39. There are no users yet, so documenting the `ontology_id` removal as a breaking user-facing change is unnecessary.
- **D-16:** Do not mutate `.planning/ROADMAP.md` or `.planning/REQUIREMENTS.md` during this phase context pass. This context decision is the planner's override for the obsolete `NEWS.md` success criterion unless the roadmap is explicitly revised later.
- **D-17:** Do not add a new `dev/lifestage/validate_39.R` script. `testthat` is the durable quality gate.
- **D-18:** Existing dev scripts should only be changed if they are actively stale enough to mislead release validation, such as expecting `ontology_id` or the old lifestage column layout.

### Agent's Discretion
- Exact inline mock payload shape, provided the tests exercise real parsing boundaries for OLS4, NVS, and BioPortal.
- Whether BioPortal missing-key coverage is separate from unauthorized/request-failure coverage.
- Whether to add a single resolver-continuation smoke test after the direct adapter tests.
- Exact wording of test descriptions and warning expectations.

</decisions>

<specifics>
## Specific Ideas

- User explicitly rejected the roadmap `NEWS.md` gate: "Don't need it. No users yet."
- The adapter tests should be small and CI-safe, not cassette-backed live-provider tests.
- Empty provider search results should be treated as ordinary "no match" outcomes; warnings are for actual endpoint, auth, or request failures.
- No new dev script should be created for Phase 39 because `devtools::test(filter = "eco_lifestage_gate")` is the real gate.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` - Phase 39 goal and success criteria. Note: the `NEWS.md` success criterion is overridden by this context.
- `.planning/REQUIREMENTS.md` - QUAL-01 mocked provider test requirement.
- `.planning/PROJECT.md` - v2.4 source-backed lifestage milestone scope.
- `.planning/STATE.md` - Current project position: Phase 39 quality gates are next.

### Prior Phase Context
- `.planning/phases/38-runtime-api-finalization/38-CONTEXT.md` - Final `eco_results()` compact/detailed output contract and `ontology_id` removal.
- `.planning/phases/37-build-patch-integration/37-CONTEXT.md` - Live/force refresh semantics and existing mocked provider patch-test expectations.
- `.planning/phases/36.2-dictionary-rebuild-validation/36.2-CONTEXT.md` - Source-backed semantic adjudication and validation philosophy.

### Product Code and Tests
- `R/eco_lifestage_patch.R` - OLS4, NVS, BioPortal provider adapters, resolver path, and live refresh behavior.
- `tests/testthat/test-eco_lifestage_gate.R` - Existing lifestage gate tests and target location for Phase 39 provider tests.
- `NEWS.md` - Obsolete Phase 39 target; do not update for `ontology_id` removal unless the roadmap is revised.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tests/testthat/test-eco_lifestage_gate.R` already defines `make_provider_row()`, `mock_ols_query()`, `mock_nvs_query()`, `empty_lifestage_candidates()`, and patch DB helpers.
- Existing lifestage tests already use `testthat::with_mocked_bindings()` with `.package = "ComptoxR"`.
- `.eco_lifestage_candidate_schema()` provides the expected zero-row candidate schema for failure and empty-response tests.

### Established Patterns
- Durable package gates live in testthat; dev scripts are secondary validation aids.
- Provider/live behavior is mocked in tests rather than recorded with VCR cassettes.
- Warnings use `cli::cli_warn()` for endpoint/key failures.
- Existing tests already guard no-live behavior in several patch paths by mocking provider helpers to stop if called.

### Integration Points
- `.eco_lifestage_query_ols4()` parses OLS4 search JSON and filters accepted ontology prefixes.
- `.eco_lifestage_nvs_index()` fetches and normalizes the NVS S11 index; `.eco_lifestage_query_nvs()` queries that local index.
- `.eco_lifestage_query_bioportal()` requires `BIOPORTAL_API_KEY`, parses BioPortal search records, and handles endpoint/auth failures.
- Existing live-refresh/force tests in `tests/testthat/test-eco_lifestage_gate.R` should be inspected for unmocked provider paths after newer providers were added.

</code_context>

<deferred>
## Deferred Ideas

- No new dev validation script for Phase 39.
- No `NEWS.md` breaking-change entry for `ontology_id` removal unless the roadmap is later revised.
- No roadmap or requirements mutation during discussion; the planner should consume this context as the active decision record.

</deferred>

---

*Phase: 39-quality-gates*
*Context gathered: 2026-04-29*
