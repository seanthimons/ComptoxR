# Codebase Concerns

**Analysis Date:** 2026-02-12

## Tech Debt

**Incomplete Generic Request Refactoring:**
- Issue: 11 functions still use direct `httr2` implementations instead of `generic_request()` or `generic_chemi_request()` templates
- Files: `R/ct_bioactivity.R`, `R/ct_descriptors.R`, `R/ct_prop.R`, `R/ct_related.R`, `R/chemi_cluster.R`, `R/chemi_functional_use.R`, `R/chemi_predict.R`, `R/chemi_safety_sections.R`, `R/epi_suite.R`, `R/util_classyfire.R`, `R/util_classyfire_wishart.R`
- Impact: Code duplication, inconsistent error handling, harder to maintain request patterns across the codebase
- Fix approach: Migrate each function to use `generic_request()` with appropriate `batch_limit`, `method`, and `path_params` parameters. Functions like `ct_bioactivity.R` have TODO comments indicating intent to migrate

**Variable API Key Handling:**
- Issue: API key functions (`ct_api_key()`, `cc_api_key()`) will abort with `cli_abort()` if key is not found, halting function execution
- Files: `R/ct_api_key.R`, `R/cc_api_key.R`, `R/z_generic_request.R` (line 140, 476)
- Impact: Function calls fail catastrophically instead of providing fallback behavior; error occurs at request time rather than during function definition
- Fix approach: Consider implementing graceful degradation - log warning and attempt request without authentication, or return NULL/empty result with informative message

## Known Bugs

**TODO in ct_bioactivity.R:**
- Symptoms: Function has uncommitted migration work indicated by TODO comment on line 1
- Files: `R/ct_bioactivity.R` (line 1)
- Trigger: Calling `ct_bioactivity()` executes custom httr2 code instead of generic template
- Workaround: Function works but should use template pattern for consistency

**Package Output Coercion Issue:**
- Symptoms: `package_sitrep()` returns messy list data instead of tibble
- Files: `R/zzz.R` (commit 4e896a0 indicates "fix output to not return messy list data")
- Trigger: Running `package_sitrep()` for diagnostics
- Workaround: None - function needs refactoring to consistently return tibbles

## Security Considerations

**API Key Leakage in VCR Cassettes:**
- Risk: API keys could be recorded in cassette files if VCR sanitization fails
- Files: `tests/testthat/helper-vcr.R` (lines 9-11), `tests/check_cassettes.R` (line 44)
- Current mitigation: VCR configured to filter `ctx_api_key` environment variable and replace with `<<<API_KEY>>>` marker
- Recommendations:
  - Before committing cassettes, run `check_cassette_safety()` helper to verify no real keys are present
  - Add pre-commit hook to validate cassettes don't contain real API keys
  - Consider adding CC API key sanitization to helper-vcr.R (currently only sanitizes ctx_api_key)

**Environment Variable Exposure via stdout:**
- Risk: Package sitrep function displays API key status, but actual key value should never be logged
- Files: `R/zzz.R` (lines 196-200), `R/package_sitrep.R`
- Current mitigation: Only status ("SET" or "NOT SET") is displayed, not actual key value
- Recommendations: Continue masking actual key values; ensure no debug output includes `Sys.getenv("ctx_api_key")`

**R ≥ 3.5.0 Support Requirement:**
- Risk: DESCRIPTION specifies R ≥ 3.5.0 (released 2019), which is very old and lacks security patches
- Files: `DESCRIPTION` (line 23)
- Current mitigation: Modern dependency versions (e.g., dplyr ≥ 1.1.4, tibble, purrr ≥ 1.0.2) require newer R versions anyway
- Recommendations: Increase minimum R version to 4.1.0 (released 2021) to align with tidyverse ecosystem requirements

## Performance Bottlenecks

**Sequential HTTP Request Execution:**
- Problem: Batched requests execute sequentially via `httr2::req_perform_sequential()` to avoid rate limits
- Files: `R/z_generic_request.R` (lines 229-234)
- Cause: EPA APIs have rate limiting; batching defaults to 200-1000 items per request with sequential batches
- Improvement path:
  - Add configurable request delay via environment variable
  - Monitor actual API rate limit headers and adapt accordingly
  - Consider implementing exponential backoff with jitter

**Memory Usage with Large Result Sets:**
- Problem: Functions bind all results into single tibble via `purrr::list_rbind()` without streaming
- Files: `R/z_generic_request.R` (line 371), `R/chemi_safety.R`, multiple ct_* functions
- Cause: All API responses collected in memory before conversion to tibble
- Improvement path: For functions handling >10k items, implement chunked processing with intermediate file writes or streaming conversion

**Unicode Replacement at Scale:**
- Problem: `clean_unicode()` loads entire unicode_map for each call and applies all replacements
- Files: `R/clean_unicode.R` (lines 49-54)
- Cause: stringi::stri_replace_all_fixed applies full map to every string even if not needed
- Improvement path: Profile actual usage; consider lazy-loading unicode_map only when data contains non-ASCII characters

## Fragile Areas

**VCR Cassette Dependency:**
- Files: `tests/testthat/fixtures/` (323 test files depend on cassettes)
- Why fragile: Tests fail if cassettes are deleted or out of sync with API responses. First test run requires valid API key to record cassettes. Cassette schema is tightly coupled to API response structure
- Safe modification:
  - Before modifying any API wrapper, regenerate affected cassettes by running tests with valid API key
  - Use `vcr::use_cassette(..., record = "new_episodes")` for partial re-recording
  - Never manually edit cassettes - regenerate them
- Test coverage: 323 test files exist; verify no orphaned cassettes via `source("tests/check_cassettes.R")`

**Generic Request Path Parameter Validation:**
- Files: `R/z_generic_request.R` (lines 91-99)
- Why fragile: `path_params` cannot be used with batching (`batch_limit > 1`). Function aborts if this rule violated. Breaking change risk if code attempts to batch with path parameters
- Safe modification: When adding new path-based endpoints, set `batch_limit = 0` or `batch_limit = 1`. Never combine `path_params` with `batch_limit > 1`
- Test coverage: Unit tests needed for path_params validation logic

**Unicode Mapping Completeness:**
- Files: `R/clean_unicode.R` (lines 81-98), `R/unicode_map.R`
- Why fragile: Function warns about unhandled Unicode characters. If new symbols appear in API responses, they won't be replaced and will trigger warnings
- Safe modification: When warnings appear, update `data-raw/unicode_map.R` and regenerate `unicode_map` via `devtools::document()`
- Test coverage: No tests for specific Unicode symbols; add snapshot tests for known edge cases

**Endpoint Configuration Hardcoding:**
- Files: `R/zzz.R` (lines 18-37 hardcode server names)
- Why fragile: EPA endpoint URLs are set during package attach. If endpoints move or API structure changes, functions may silently call wrong URLs
- Safe modification: Verify server URLs via `ctx_server()`, `chemi_server()`, `epi_server()`, `eco_server()` functions before API changes propagate
- Test coverage: `run_setup()` pings endpoints but doesn't validate response schema

## Scaling Limits

**Cassette File Size:**
- Current capacity: 323 cassettes × ~5-50KB average = ~10-15MB total fixture storage
- Limit: Git repository size bloat if cassettes grow unchecked; slow test execution with large YAML parsing
- Scaling path: Archive old cassettes; implement cassette rotation based on age; consider switching to binary format (Protocol Buffers) instead of YAML

**Test Suite Execution Time:**
- Current capacity: 323 test files with parallel execution (`Config/testthat/parallel: true`)
- Limit: Unknown performance characteristics; GHA workflow requirement is <60s total
- Scaling path: Monitor GHA workflow duration; split tests into separate jobs if combined time exceeds 120s; cache dependencies between runs

**API Rate Limiting:**
- Current capacity: Unknown per-API rate limit; defaults to batch_limit=1000 for most endpoints
- Limit: Sequential batching will slow down as query sizes increase; no backpressure mechanism
- Scaling path: Document actual rate limits for each EPA endpoint; implement adaptive rate limiting based on 429 responses; add batch_limit as user-configurable parameter

## Dependencies at Risk

**R >= 3.5.0:**
- Risk: Very old minimum version; security and compatibility issues
- Impact: New maintainers unlikely to test on R 3.5; modern tidyverse packages already require R >= 4.1
- Migration plan: Update DESCRIPTION minimum to R (>= 4.1.0); test on R 4.1 and latest release in GHA workflow

**httr2 (no version pin):**
- Risk: Major API changes could break request patterns; no constraint on allowed versions
- Impact: Upstream breaking changes could silently break all requests
- Migration plan: Add version constraint `httr2 (>= 1.0.0)` to DESCRIPTION; document minimum version required

**ctxR Dependency in Suggests:**
- Risk: External package with unknown maintenance status
- Impact: Optional but if used, could break workflows
- Migration plan: Verify ctxR stability or replace with direct httr2 usage if deprecated

## Missing Critical Features

**Request Retry Logic:**
- Problem: No built-in retry mechanism for transient failures
- Blocks: Robust batch processing of large queries; tests sensitive to temporary API outages
- Implementation: Add exponential backoff wrapper around `httr2::req_perform()` in generic_request functions

**Rate Limit Headers Parsing:**
- Problem: Functions don't parse or respect X-RateLimit-* headers from API responses
- Blocks: Adaptive batching based on actual API rate limits; early backoff before hitting limits
- Implementation: Extract rate limit headers in `generic_request()` response processing; store in environment variable for next batch

**Response Schema Validation:**
- Problem: No schema validation after API responses are parsed
- Blocks: Early detection of API breaking changes; better error messages when unexpected response structure
- Implementation: Load expected response schema; validate `resp_body_json()` result against schema before tidying

**Bulk Operation Atomicity:**
- Problem: If batch operation fails mid-way, no rollback or partial result handling
- Blocks: Batch operations across multiple APIs cannot be transactional
- Implementation: Track success/failure per-batch item; return tagged results (success, skip, error)

## Test Coverage Gaps

**Path Parameter Validation:**
- What's not tested: `path_params` validation logic in generic_request (lines 91-99)
- Files: `R/z_generic_request.R`
- Risk: Refactoring path_params handling could break silently without test coverage
- Priority: HIGH - This validation prevents incorrect API calls

**Non-JSON Response Handling:**
- What's not tested: Image responses (image/png, image/svg) and text/plain response paths in generic_request (lines 246-299)
- Files: `R/z_generic_request.R`
- Risk: Image endpoints may fail or return incorrect types without detection
- Priority: MEDIUM - Less common use case but affects specific chemi endpoints

**Error Recovery Patterns:**
- What's not tested: Partial batch failures; mixed success/error responses in `req_perform_sequential()` results
- Files: `R/z_generic_request.R` (lines 230-234)
- Risk: Functions may silently drop failed batches without warning user
- Priority: HIGH - Silent data loss is critical

**Unicode Edge Cases:**
- What's not tested: Nested Unicode, combining marks, right-to-left text, emoji handling
- Files: `R/clean_unicode.R`
- Risk: Unhandled Unicode types silently pass through instead of being replaced
- Priority: LOW - Mostly cosmetic but affects data quality

**Server Configuration State:**
- What's not tested: Multiple calls to `*_server()` functions; state consistency after switching servers
- Files: Environment variables `ctx_burl`, `chemi_burl`, `epi_burl`, `eco_burl`
- Risk: Functions may use stale server URLs if user switches environments mid-session
- Priority: MEDIUM - Affects advanced users switching between production/staging

---

*Concerns audit: 2026-02-12*
