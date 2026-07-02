---
phase: 39-quality-gates
created: 2026-04-29
status: complete
---

# Phase 39: Quality Gates - Research

## Research Question

What needs to be known to plan CI-safe mocked provider adapter tests for OLS4, NVS, and BioPortal without reopening the v2.4 lifestage design?

## Scope Summary

Phase 39 should focus on the durable quality gate for provider adapters:

- direct adapter tests for `.eco_lifestage_query_ols4()`, `.eco_lifestage_nvs_index()` / `.eco_lifestage_query_nvs()`, and `.eco_lifestage_query_bioportal()`
- inline mocked provider responses only
- no VCR cassettes, no live API calls, and no required `BIOPORTAL_API_KEY`
- no new `dev/lifestage/validate_39.R`
- no `NEWS.md` entry for the removed `ontology_id` output, because `39-CONTEXT.md` explicitly overrides the obsolete roadmap criterion

## Current Code Findings

### Shared Candidate Schema

`R/eco_lifestage_patch.R` defines `.eco_lifestage_candidate_schema()` with this provider candidate contract:

```r
source_provider
source_ontology
source_term_id
source_term_label
source_term_definition
candidate_aliases
source_release
source_match_method
```

Phase 39 tests should assert this schema for all provider happy, empty, and failure paths. Empty and failure paths should return the zero-row version of this schema.

### OLS4 Adapter

`.eco_lifestage_query_ols4(term)`:

- calls `https://www.ebi.ac.uk/ols4/api/search` through `httr2::req_perform()`
- parses `resp_body_string()` with `jsonlite::fromJSON(simplifyDataFrame = TRUE)`
- emits a warning and returns `.eco_lifestage_candidate_schema()` on request/parsing failure
- returns an empty candidate schema silently when `response$response$docs` is missing or empty
- maps OLS4 records to provider candidate columns
- filters accepted `obo_id` prefixes, including `UBERON:`, `PO:`, `XAO:`, `ECOCORE:`, `EFO:`, `ZFA:`, `FBdv:`, and `MeSH:`

Planning implication: the happy-path test should include at least one accepted `UBERON:` or `PO:` row and one rejected non-prefix row to prove prefix filtering. Failure and empty tests should assert warning behavior only for actual request failure, not for a valid empty response.

### NVS Adapter

`.eco_lifestage_nvs_index(refresh = FALSE)`:

- caches the parsed index in `.ComptoxREnv$eco_lifestage_nvs_index`
- posts a SPARQL query to `https://vocab.nerc.ac.uk/sparql/sparql`
- parses `payload$results$bindings`
- emits a warning and returns `.eco_lifestage_candidate_schema()` on endpoint failure
- currently emits a warning when the endpoint succeeds but returns no bindings
- creates provider candidate rows with `source_provider = "NVS"`, `source_ontology = "S11"`, `source_term_id` extracted from the NVS URI, and `source_match_method = "nvs_sparql"`

`.eco_lifestage_query_nvs(term)`:

- reads the cached/indexed table through `.eco_lifestage_nvs_index()`
- filters by normalized term tokens across `source_term_label` and `candidate_aliases`
- currently returns a zero-column `tibble()` when the index is empty or the query term has no usable tokens

Planning implication: Phase 39 should include a small implementation cleanup so NVS empty/no-token cases return `.eco_lifestage_candidate_schema()`, and a valid empty NVS response is silent. That aligns NVS with decisions D-03, D-06, D-07, and D-08.

### BioPortal Adapter

`.eco_lifestage_query_bioportal(term)`:

- reads `BIOPORTAL_API_KEY` from the environment
- warns and returns `.eco_lifestage_candidate_schema()` when the key is missing
- calls `https://data.bioontology.org/search` through `httr2::req_perform()` when a key is present
- parses `resp_body_json()` and maps `response$collection` records to provider candidate rows
- emits a warning and returns empty schema on endpoint/auth failure, with a specific hint for HTTP 401
- returns empty schema silently when the response has no collection records

Planning implication: direct tests should enforce both keyless CI safety and keyed request behavior. A keyless test can prove no network call happens by making `httr2::req_perform()` a sentinel that fails if reached.

### Existing Test Surface

`tests/testthat/test-eco_lifestage_gate.R` already contains useful helpers:

- `make_provider_row()`
- `mock_ols_query()`
- `mock_nvs_query()`
- `empty_lifestage_candidates()`
- `make_patch_db()`
- local DuckDB fixtures used by patch and runtime tests

The file already uses `testthat::with_mocked_bindings(..., .package = "ComptoxR")` for internal provider helpers. For Phase 39 direct adapter tests, the executor should mock exported `httr2` functions in the `httr2` namespace, especially `req_perform()`, `resp_body_string()`, and `resp_body_json()`, so adapter internals are exercised without network access.

The existing live-refresh and force patch tests already mock OLS4, NVS, BioPortal, Wikidata, AGROVOC, DEVSTAGE, PO, and curated candidates. They should still be inspected while editing to make sure no newly required provider path can leak to a live request.

## Recommended Test Design

### Helper Pattern

Add small test-only helpers near the existing lifestage gate helpers:

- `expect_candidate_schema(x)` to assert the exact candidate columns
- `expect_empty_candidate_schema(x)` to assert schema plus zero rows
- optional local mock wrappers for `httr2::req_perform()` and response readers

The tests should keep mock payloads inline. Do not add JSON fixture files.

### OLS4 Coverage

Add tests for:

1. happy path parses OLS4 docs, preserves expected fields, and filters unsupported prefixes
2. request failure warns and returns empty candidate schema
3. valid empty response returns empty candidate schema without warning

### NVS Coverage

Add tests for:

1. NVS index happy path parses S11 bindings and `.eco_lifestage_query_nvs()` finds a matching term
2. endpoint failure warns and returns empty candidate schema
3. valid empty bindings return empty candidate schema without warning
4. query against empty index or blank/unmatchable term returns empty candidate schema

The implementation should reset `.ComptoxREnv$eco_lifestage_nvs_index` around tests that exercise cache behavior.

### BioPortal Coverage

Add tests for:

1. happy path parses collection records into BioPortal candidate rows
2. missing `BIOPORTAL_API_KEY` warns, returns empty candidate schema, and never reaches `httr2::req_perform()`
3. request/auth failure warns and returns empty candidate schema
4. valid empty collection returns empty candidate schema without warning

Use `withr::with_envvar()` to control the BioPortal key.

## Validation Architecture

Phase 39 has existing R/testthat infrastructure and needs no Wave 0 setup.

- Framework: `testthat` through `devtools`
- Quick command: `Rscript -e "devtools::test(filter='eco_lifestage_gate')"`
- Full command for this phase: `Rscript -e "devtools::test(filter='eco_lifestage_gate')"`
- Expected feedback latency: 60-180 seconds
- Manual-only validation: none; human review is limited to confirming no `NEWS.md`, dev validation script, cassette, or external fixture churn was introduced

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Mocking only high-level internal functions misses adapter parsing bugs | Directly call adapter functions and mock `httr2` response boundaries |
| Tests accidentally hit live providers | Sentinel `httr2::req_perform()` mocks fail on unexpected calls |
| NVS cache contaminates test order | Clear and restore `.ComptoxREnv$eco_lifestage_nvs_index` around NVS tests |
| Empty provider response semantics drift | Add no-warning assertions for valid empty OLS4, NVS, and BioPortal responses |
| Roadmap still mentions `NEWS.md` | Plan must treat `39-CONTEXT.md` as the active decision record and not update `NEWS.md` |

## Planning Recommendation

Create one Wave 1 plan. It should be TDD-oriented:

1. add direct mocked adapter tests and helper assertions
2. make minimal NVS implementation fixes revealed by those tests
3. tighten any existing provider mocks in live/force patch tests if inspection finds a live-leak risk
4. run the focused testthat gate and inspect the diff

## RESEARCH COMPLETE
