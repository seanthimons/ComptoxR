# Testing Quick Start Guide

## TL;DR - Get to 40% Coverage in 30 Minutes

```r
# 1. Generate all test files
source("generate_tests.R")
generate_tests()

# 2. Set your API key
Sys.setenv(ctx_api_key = "YOUR_KEY_HERE")

# 3. Run tests (records cassettes on first run)
devtools::test()

# 4. Check coverage
cov <- covr::package_coverage()
print(cov)
covr::report(cov)  # Opens HTML report
```

## Step-by-Step Instructions

### 1. Generate Test Files (5 minutes)

```r
# Load the package
library(ComptoxR)

# Run the test generator
source("generate_tests.R")
results <- generate_tests()

# This creates test files for ~33 functions:
# - tests/testthat/test-ct_hazard.R
# - tests/testthat/test-ct_cancer.R
# - tests/testthat/test-chemi_toxprint.R
# ... and so on
```

### 2. Set Up API Key (1 minute)

You need a valid API key to record cassettes on the first run:

```r
# Set API key for this session
Sys.setenv(ctx_api_key = "YOUR_KEY_HERE")

# Or add to .Renviron permanently
usethis::edit_r_environ()
# Add: ctx_api_key=YOUR_KEY_HERE
```

Request an API key by emailing: ccte_api@epa.gov

### 3. Run Tests & Record Cassettes (10-15 minutes)

```r
# Run all tests (first run records cassettes from production API)
devtools::test()

# Or run specific test file
testthat::test_file("tests/testthat/test-ct_hazard.R")

# Or run tests with detailed output
devtools::test(reporter = "progress")
```

**What happens:**
- Tests execute and hit the production API
- Responses are recorded to YAML files (cassettes)
- Cassettes are saved in `tests/testthat/fixtures/`
- Future runs use cassettes (no API needed)

### 4. Check Coverage (5 minutes)

```r
# Calculate coverage
cov <- covr::package_coverage()

# Print summary
print(cov)
# ComptoxR Coverage: 42.35%
# R/z_generic_request.R: 78.50%
# R/ct_hazard.R: 95.20%
# ...

# Open interactive HTML report
covr::report(cov)

# Or save report to file
covr::report(cov, file = "coverage_report.html")
```

### 5. Review & Commit (5 minutes)

```r
# Check that cassettes don't contain API keys
source("tests/testthat/helper-vcr.R")
check_cassette_safety("ct_hazard_single.yml")

# Review cassettes
list_cassettes()

# Commit tests and cassettes
git add tests/testthat/test-*.R
git add tests/testthat/fixtures/*.yml
git commit -m "Add test suite with VCR cassettes"
```

## Test Structure Overview

Each test file follows this pattern:

```r
# tests/testthat/test-ct_hazard.R

# Test 1: Basic functionality
test_that("ct_hazard works with single DTXSID", {
  vcr::use_cassette("ct_hazard_single", {
    result <- ct_hazard("DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})

# Test 2: Batch processing
test_that("ct_hazard handles batch requests", {
  vcr::use_cassette("ct_hazard_batch", {
    result <- ct_hazard(c("DTXSID7020182", "DTXSID5032381"))
    expect_s3_class(result, "tbl_df")
  })
})

# Test 3: Error handling
test_that("ct_hazard handles invalid input", {
  vcr::use_cassette("ct_hazard_invalid", {
    expect_warning(result <- ct_hazard("INVALID_ID"))
  })
})
```

## Common Test Patterns

### Pattern 1: Testing Wrapper Functions

```r
test_that("function returns expected structure", {
  vcr::use_cassette("cassette_name", {
    result <- my_function("DTXSID7020182")

    # Type checks
    expect_s3_class(result, "tbl_df")

    # Structure checks
    expect_true(ncol(result) > 0)

    # Content checks
    if (nrow(result) > 0) {
      expect_true("dtxsid" %in% colnames(result))
    }
  })
})
```

### Pattern 2: Testing with Options

```r
test_that("function respects parameters", {
  vcr::use_cassette("function_with_options", {
    result <- my_function(
      "DTXSID7020182",
      tidy = FALSE,
      options = list(param = "value")
    )

    expect_type(result, "list")
  })
})
```

### Pattern 3: Testing Error Handling

```r
test_that("function handles errors gracefully", {
  vcr::use_cassette("function_error", {
    expect_warning(
      result <- my_function("INVALID_INPUT"),
      "No results|failed|error"
    )

    expect_true(is.null(result) || nrow(result) == 0)
  })
})
```

### Pattern 4: Testing Without API (Debug Mode)

```r
test_that("function constructs request correctly", {
  Sys.setenv(run_debug = "TRUE")
  on.exit(Sys.setenv(run_debug = "FALSE"))

  output <- capture_output(
    my_function("DTXSID7020182")
  )

  expect_match(output, "POST")
  expect_match(output, "endpoint_name")
})
```

### Pattern 5: Testing With Mocks

```r
test_that("function processes response correctly", {
  test_data <- list(list(id = 1, value = "test"))

  testthat::with_mocked_bindings(
    req_perform = function(req) {
      httr2::response(
        status_code = 200,
        body = charToRaw(jsonlite::toJSON(test_data))
      )
    },
    .package = "httr2",
    {
      result <- my_function("test_input")
      expect_s3_class(result, "tbl_df")
      expect_equal(nrow(result), 1)
    }
  )
})
```

## VCR Cassette Management

### Common VCR Operations

```r
# Load VCR helpers
source("tests/testthat/helper-vcr.R")

# List all cassettes
cassettes <- list_cassettes()
print(cassettes)

# Delete specific cassettes to re-record
delete_cassettes("ct_hazard")

# Delete all cassettes (use with caution!)
delete_all_cassettes()

# Check cassette for sensitive data
check_cassette_safety("ct_hazard_single.yml")
```

### Re-recording Cassettes

If the API changes or you need fresh data:

```r
# 1. Delete old cassettes
delete_cassettes("ct_hazard")

# 2. Make sure API key is set
Sys.setenv(ctx_api_key = "YOUR_KEY")

# 3. Run tests (re-records from production)
testthat::test_file("tests/testthat/test-ct_hazard.R")

# 4. Check new cassettes
check_cassette_safety("ct_hazard_single.yml")
```

## Customizing Generated Tests

The generated tests are templates - customize them for your needs:

### Add More Test Cases

```r
# Add to generated test file
test_that("ct_hazard filters by hazard type", {
  vcr::use_cassette("ct_hazard_filtered", {
    result <- ct_hazard(
      "DTXSID7020182",
      hazard_type = "cancer"
    )
    expect_s3_class(result, "tbl_df")
  })
})
```

### Test Integration Workflows

```r
test_that("complete workflow works", {
  vcr::use_cassette("workflow_hazard_assessment", {
    # Step 1: Get details
    details <- ct_details("50-00-0")

    # Step 2: Get hazard
    hazard <- ct_hazard(details$dtxsid)

    # Step 3: Check results
    expect_s3_class(hazard, "tbl_df")
  })
})
```

### Test Edge Cases

```r
test_that("function handles edge cases", {
  # Empty vector
  expect_warning(result <- ct_hazard(character(0)))

  # NULL input
  expect_error(ct_hazard(NULL))

  # Very long vector (batching)
  vcr::use_cassette("ct_hazard_large_batch", {
    large_input <- rep("DTXSID7020182", 500)
    result <- ct_hazard(large_input)
    expect_s3_class(result, "tbl_df")
  })
})
```

## Troubleshooting

### "No cassette found" error

**Problem:** Test runs but can't find cassette

**Solution:**
```r
# Run test to create cassette
devtools::test()

# Or manually create with API key set
Sys.setenv(ctx_api_key = "YOUR_KEY")
testthat::test_file("tests/testthat/test-ct_hazard.R")
```

### "API key not set" error

**Problem:** Running tests without API key on first run

**Solution:**
```r
# Set API key
Sys.setenv(ctx_api_key = "YOUR_KEY")

# Or use existing cassettes (skip recording)
# Cassettes should already exist if tests were run before
```

### Coverage not improving

**Problem:** Tests run but coverage stays low

**Solution:**
```r
# Check which lines are uncovered
cov <- covr::package_coverage()
covr::report(cov)  # Interactive report shows uncovered lines

# Focus on:
# 1. Branches (if/else statements)
# 2. Error handling paths
# 3. Optional parameters
```

### Tests fail intermittently

**Problem:** Tests pass sometimes but fail other times

**Solution:**
```r
# Use cassettes for consistent results
vcr::use_cassette("test_name", {
  # test code
})

# Or use mocks
testthat::with_mocked_bindings(...)
```

### Cassettes contain API key

**Problem:** Committed cassettes leak API key

**Solution:**
```r
# Check all cassettes
source("tests/testthat/helper-vcr.R")
check_all_cassettes()

# If found, delete and re-record with filtering
delete_cassettes("problematic_cassette")

# Configure VCR to filter keys (in setup.R)
vcr::vcr_configure(
  filter_request_headers = list(Authorization = "<<<REDACTED>>>")
)
```

## Next Steps After Quick Start

Once you have 40%+ coverage:

1. **Improve quality of generated tests**
   - Add more assertions
   - Test optional parameters
   - Add edge cases

2. **Test utility functions**
   - `extract_cas()`
   - `is_cas()`
   - `clean_unicode()`

3. **Test integration workflows**
   - Multi-function pipelines
   - Data transformations
   - Error propagation

4. **Increase coverage targets**
   - 60% coverage: Add utility function tests
   - 80% coverage: Add integration tests
   - 90% coverage: Add edge cases and error paths

5. **Set up CI/CD**
   - Run tests on every commit
   - Fail build if coverage drops
   - Cache cassettes for faster CI

## Resources

- **Full testing strategy:** See `TESTING_STRATEGY.md`
- **Test generator code:** See `generate_tests.R`
- **Helper functions:** See `tests/testthat/helper-*.R`
- **Example tests:**
  - `test-ct_hazard.R` - CT function example
  - `test-chemi_toxprint.R` - Chemi function example
  - `test-generic_request.R` - Template function tests

## Get Help

If you run into issues:

1. Check `TESTING_STRATEGY.md` for detailed guidance
2. Review existing test files for patterns
3. Use debug mode to inspect requests without hitting API
4. Check VCR documentation: https://docs.ropensci.org/vcr/
