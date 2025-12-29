# Testing Strategy: Two-Tier Approach

This document outlines the testing strategy for `ComptoxR` following its major refactor. The goal is to maximize code coverage and reliability while minimizing runtime and API usage costs.

## Tier 1: Core Logic & Generic Requests (Mocked/Offline)

We focus on testing the foundational "engine" functions: `generic_request()` and `generic_chemi_request()`.

### Strategy
- **Mocking**: Use `httptest2` and `webmockr` to simulate API responses. This allows us to test edge cases (404s, 500s, empty results, malformed JSON) without hitting production.
- **Dry Runs**: Use the `run_debug` environment flag and `httr2::req_dry_run()` to verify:
    - Correct URL construction.
    - Proper header injection (API keys).
    - Batching logic (ensuring large queries are split into correct chunk sizes).
- **Tidying**: Test the conversion from raw JSON lists to tidy tibbles/tibbles with complex nested data.

## Tier 2: Endpoint Connectivity (Recorded/vcr)

For individual wrapper functions (e.g., `ct_hazard()`, `ct_details()`), we verify the "plumbing".

### Strategy
- **vcr Integration**: Use `vcr::use_cassette()` to record a single, minimal request for each function.
- **Grouped Tests**: Instead of 100+ small files, tests are grouped by API service (e.g., `test-hazards.R`) to simplify management.
- **Golden Data**: Use a consistent set of "Golden DTXSIDs" for connectivity tests to keep cassettes uniform and predictable.

## Security & Best Practices

- **Redaction**: All cassettes are configured to automatically redact `x-api-key` headers.
- **Auth Simulation**: `setup.R` ensures a dummy API key is present so tests don't fail in restricted environments (CI).
- **Offline First**: Tier 1 tests must run without network access. Tier 2 tests run against recorded cassettes in milliseconds.

## Adding New Tests

When adding a new function, follow this workflow:

### 1. Identify the Category
Add your test to the appropriate grouped file in `tests/testthat/` (e.g., `test-ctx_dashboard.R`).

### 2. Implement a Tier 2 Sanity Check
Use the following template to prove the function points to the correct endpoint:

```r
test_that("new_function connects and returns data", {
  skip_if_offline() 
  skip_if_no_key() 
  
  vcr::use_cassette("new_function_simple", {
    res <- new_function(test_dtxsid) # Use the global test_dtxsid
    expect_valid_tibble(res)
  })
})
```

### 3. Record the Cassette
Run the test locally with a real API key. `vcr` will record it automatically:
```bash
export ctx_api_key="YOUR_KEY"
R -e 'devtools::test(filter = "filename")'
```

### 4. Verify Redaction
Check the new `.yml` in `tests/testthat/fixtures/` to ensure the API key is replaced with `<<<API_KEY>>>`.
