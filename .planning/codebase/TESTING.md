# Testing Patterns

**Analysis Date:** 2026-02-12

## Test Framework

**Runner:**
- testthat 3.0.0+
- Config: `tests/testthat/setup.R` (global test configuration)
- Package configuration in DESCRIPTION: `Config/testthat/edition: 3` and `Config/testthat/parallel: true`

**Assertion Library:**
- testthat built-in expectations (e.g., `expect_equal()`, `expect_true()`, `expect_s3_class()`)
- Custom wrapper: `expect_valid_tibble()` in `tests/testthat/helper-api.R`

**Run Commands:**
```r
devtools::test()              # Run all tests
testthat::test_file("tests/testthat/test-ct_hazard.R")  # Run specific test file
devtools::check()             # Comprehensive R CMD check (includes tests)
covr::package_coverage()      # Run with coverage report
```

**GitHub Actions (automated):**
```bash
Rscript -e 'devtools::test(filter = "pipeline")'     # Integration tests
Rscript -e 'devtools::check()'                        # R CMD check on push/PR
```

## Test File Organization

**Location:**
- `tests/testthat/test-*.R`: Function-specific tests (323 test files)
- `tests/testthat/helper-*.R`: Shared helpers and utilities
- `tests/testthat/setup.R`: Global configuration and test environment initialization
- `tests/testthat/fixtures/`: VCR cassettes (YAML files for recorded HTTP responses)

**Naming:**
- Test file: `test-{function_name}.R`
- Cassette: `{function_name}_{variant}.yml`
- Examples:
  - `test-ct_hazard.R` → cassettes `ct_hazard_single.yml`, `ct_hazard_example.yml`
  - `test-chemi_toxprint.R` → cassettes `chemi_toxprint_single.yml`, `chemi_toxprint_error.yml`

**Structure:**
```
tests/testthat/
├── setup.R                     # Global config (API keys, server URLs, batch limits)
├── helper-api.R                # API helpers (skip functions, custom expectations)
├── helper-vcr.R                # VCR configuration for cassette recording
├── test-generic_request.R      # Tests for core template function
├── test-generic_chemi_request.R # Tests for chemi template
├── test-ct_hazard.R            # Function-specific tests (323 of these)
├── test-chemi_toxprint.R
└── fixtures/
    ├── ct_hazard_single.yml
    ├── chemi_toxprint_single.yml
    └── ... (100+ cassettes)
```

## Test Structure

**Suite Organization:**
```r
test_that("brief description of what is tested", {
  vcr::use_cassette("cassette_name", {
    result <- function_under_test(arg1, arg2)
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 2)
  })
})
```

**Patterns:**

1. **Setup Pattern (global):**
   - `setup.R` initializes environment variables at test suite startup:
     ```r
     Sys.setenv("ctx_api_key" = Sys.getenv("ctx_api_key", "dummy_ctx_key"))
     Sys.setenv("batch_limit" = "100")
     Sys.setenv("run_debug" = "FALSE")
     Sys.setenv("run_verbose" = "FALSE")
     Sys.setenv("ctx_burl" = "https://comptox.epa.gov/ctx-api/")
     ```
   - Ensures consistent environment across all developers
   - Provides dummy keys for tests that don't need real API access

2. **Per-test Setup Pattern:**
   - `on.exit()` blocks restore state after test completes:
     ```r
     test_that("test_name", {
       Sys.setenv(run_debug = "TRUE")
       on.exit(Sys.setenv(run_debug = "FALSE"))
       # Test code here
     })
     ```
   - Critical for environment variable tests (prevents cross-test pollution)

3. **Teardown Pattern:**
   - `on.exit()` is R's equivalent of finally/cleanup
   - Always used when modifying environment variables or global state
   - Example from `test-generic_request.R`:
     ```r
     test_that("test", {
       Sys.setenv(batch_limit = "2")
       on.exit({
         Sys.setenv(run_debug = "FALSE")
         Sys.setenv(batch_limit = "100")
       })
       # Test assertions
     })
     ```

4. **Assertion Pattern:**
   - Simple boolean checks: `expect_true(condition)`, `expect_false(condition)`
   - Type checks: `expect_s3_class(result, "tbl_df")`, `expect_type(result, "list")`
   - Equality: `expect_equal(nrow(res), 2)`, `expect_equal(colnames(res), c("id", "name"))`
   - Pattern matching: `expect_match(output, "POST")`, `expect_match(output, "\\[\\s*\"DTXSID7020182\"\\s*\\]")`
   - Warnings: `expect_warning(expr, "pattern")`
   - Custom: `expect_valid_tibble(result)` (checks s3_class and nrow >= 0)

## Mocking

**Framework:**
- `testthat::with_mocked_bindings()` for unit test mocking
- `vcr` package for HTTP interaction recording/replay (integration tests)

**Mock HTTP Responses:**
```r
testthat::with_mocked_bindings(
  req_perform = function(req) {
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw(jsonlite::toJSON(test_data, auto_unbox = TRUE))
    )
  },
  .package = "httr2",
  {
    result <- generic_request("dummy", "endpoint", method = "POST")
    expect_s3_class(result, "tbl_df")
  }
)
```

**Mock Debug Output:**
```r
test_that("debug output test", {
  Sys.setenv(run_debug = "TRUE")
  output <- capture_output(
    generic_request(query = "DTXSID7020182", endpoint = "hazard", method = "POST")
  )
  expect_match(output, "POST")
  expect_match(output, "\\[\\s*\"DTXSID7020182\"\\s*\\]")
})
```

**What to Mock:**
- HTTP responses via `testthat::with_mocked_bindings()`
- External services that don't have recorded cassettes
- Network-dependent code paths (offline testing)

**What NOT to Mock:**
- Internal helper functions (test the actual behavior)
- Data transformation logic (test against real data)
- VCR cassette integration (use cassettes for API calls)

## Fixtures and Factories

**Test Data:**
- Global test DTXSID: `test_dtxsid <- "DTXSID7020182"` (Benzene) in `setup.R`
- Used consistently across test files
- Allows easy re-recording of cassettes

**VCR Cassettes (recorded HTTP interactions):**
```r
test_that("chemi_toxprint works with single input", {
    vcr::use_cassette("chemi_toxprint_single", {
        result <- chemi_toxprint(query = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})
```

**Location:**
- Cassettes: `tests/testthat/fixtures/{cassette_name}.yml`
- Configured in `helper-vcr.R`:
  ```r
  vcr_dir <- "../testthat/fixtures"
  vcr::vcr_configure(
    dir = vcr_dir,
    filter_sensitive_data = list(
      "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
    )
  )
  ```

**Recording New Cassettes:**
1. First run with real API key: `Sys.setenv(ctx_api_key = "YOUR_REAL_KEY")`
2. VCR automatically records HTTP interactions to YAML
3. Subsequent runs use cached responses (no API key needed)
4. Before committing: Verify cassettes have `<<<API_KEY>>>` not actual keys
5. Helper function: `check_cassette_safety("cassette_name")` (in CLAUDE.md)

## Coverage

**Requirements:**
- R/ package code: ≥75% (rOpenSci requirement, checked by Codecov)
- dev/ internal tooling: ≥80% (GHA only, not Codecov)
- New code patches: ≥80% (Codecov threshold: 0% wiggle room)

**View Coverage:**
```r
covr::package_coverage()      # Overall package coverage
covr::file_coverage(          # Specific files
  source_files = "R/generic_request.R",
  test_files = "tests/testthat/test-generic_request.R"
)
```

**CI/CD Enforcement:**
- GHA workflow (`.github/workflows/pipeline-tests.yml`):
  - Fails if R/ coverage < 75%
  - Fails if dev/ coverage < 80%
  - Uploads R/ coverage to Codecov (dev/ intentionally excluded)
- Codecov configuration (`codecov.yml`):
  - dev/ ignored (not shipped package code)
  - tests/ ignored (test code itself not counted)

## Test Types

**Unit Tests:**
- Scope: Individual functions with mocked dependencies
- Approach: Use `with_mocked_bindings()` for HTTP mocking
- Example: `test-generic_request.R` (dry-run tests with mocked output)
- Coverage: Batching logic, input validation, response parsing

**Integration Tests:**
- Scope: End-to-end API workflows with real or cassette-recorded responses
- Approach: Use `vcr::use_cassette()` to replay HTTP interactions
- File naming: Test functions with cassette support (323 test files)
- Coverage: Actual API behavior, response handling, tibble conversion
- Filter: Tests matching `"pipeline"` pattern run in GHA integration job

**E2E Tests:**
- Not formally defined; integration tests serve this purpose
- VCR cassettes ensure reproducible HTTP interactions
- GHA runs integration tests on PR with `devtools::test(filter = "pipeline")`

## Common Patterns

**Async Testing:**
- R is single-threaded; httr2 handles async requests internally
- Tests verify synchronous behavior:
  ```r
  result <- function_call()  # Waits for completion
  expect_true(is.data.frame(result))
  ```
- Timeout handled via httr2: `httr2::req_timeout(seconds)`

**Error Testing:**
```r
test_that("handles invalid input gracefully", {
    vcr::use_cassette("function_error", {
        result <- suppressWarnings(function_name(query = "INVALID_ID"))
        # Expect empty/null result or graceful failure
        expect_true(
          is.null(result) ||
          (is.data.frame(result) && nrow(result) == 0) ||
          (is.list(result) && length(result) == 0)
        )
    })
})
```

**Regex Pattern Matching in Dry Runs:**
```r
test_that("request construction is correct", {
  Sys.setenv(run_debug = "TRUE")
  output <- capture_output(
    generic_request(
      query = c("A", "B", "C"),
      endpoint = "test",
      method = "POST"
    )
  )
  # Match JSON array in debug output
  expect_match(output, "\\[\\s*\"A\",\\s*\"B\"\\s*\\]")
})
```

**Skip Patterns (helper-api.R):**
```r
skip_if_offline <- function() {
  if (!curl::has_internet()) {
    testthat::skip("No internet connection")
  }
}

skip_if_no_key <- function() {
  key <- Sys.getenv("ctx_api_key")
  if (key == "" || key == "dummy_ctx_key") {
    testthat::skip("No real API key available")
  }
}
```

## Test Generation

**Pattern:**
- Metadata-based test generator creates template tests (323 files auto-generated)
- Tests follow standardized structure:
  1. Single input test with cassette
  2. Documented example test
  3. Error handling test (invalid input)
- Each test uses `vcr::use_cassette()` for HTTP mocking
- Template tests are safe to extend (add additional assertions)

**Generated Test Example:**
```r
test_that("chemi_toxprint works with single input", {
    vcr::use_cassette("chemi_toxprint_single", {
        result <- chemi_toxprint(query = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_toxprint handles invalid input gracefully", {
    vcr::use_cassette("chemi_toxprint_error", {
        result <- suppressWarnings(chemi_toxprint(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 0))
    })
})
```

---

*Testing analysis: 2026-02-12*
