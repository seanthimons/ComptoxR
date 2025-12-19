# Testing Guide for ComptoxR

This directory contains the test suite for ComptoxR using `testthat` (version 3) and `vcr` for HTTP interaction recording.

## Setup

### Prerequisites

1. Install required packages:
```r
install.packages(c("testthat", "vcr"))
```

2. Set up your API key:
```r
Sys.setenv(ctx_api_key = "YOUR_API_KEY_HERE")
```

3. Set up base URL (if not using default):
```r
Sys.setenv(ctx_burl = "https://api-ccte.epa.gov/")
```

## Testing Workflow

**ComptoxR tests are designed to ensure accuracy by always running against production servers initially:**

1. **First run**: Tests connect to production API and record responses (requires API key)
2. **Subsequent runs**: Tests use recorded cassettes (API key optional)
3. **When updating**: Delete cassettes to re-record from production

This ensures your tests always reflect the actual production API behavior.

## Running Tests

### Run all tests
```r
# From R console
devtools::test()

# Or using testthat directly
testthat::test_dir("tests/testthat")
```

### Run specific test file
```r
testthat::test_file("tests/testthat/test-ct_env_fate.R")
```

### Run tests with coverage
```r
covr::package_coverage()
```

## Using vcr for HTTP Mocking

### What is vcr?

`vcr` records HTTP interactions and replays them during subsequent test runs. This:
- **ALWAYS hits production servers on first run** to record accurate responses
- Makes subsequent test runs faster (no real API calls after recording)
- Makes tests more reliable (no network dependencies after recording)
- Allows testing without API key (using recorded cassettes after first run)
- Prevents hitting API rate limits during development

### How it works

1. **First run (PRODUCTION)**: Tests hit the live production API and vcr records HTTP requests/responses to YAML files (cassettes) in `tests/testthat/fixtures/`
2. **Subsequent runs (CACHED)**: vcr replays the recorded responses instead of making real API calls

**The first test run REQUIRES a valid API key** because it must connect to production servers.

### Initial setup - Recording from production

1. **Set your API key** (required for first run):
   ```r
   Sys.setenv(ctx_api_key = "YOUR_REAL_API_KEY")
   ```

2. **Run tests** - vcr will hit production and record cassettes:
   ```r
   devtools::test()
   ```

   You should see: `Using production API with key: YOUR_KEY...`

3. **Verify cassettes were created**:
   ```r
   list.files("tests/testthat/fixtures", pattern = "\\.yml$")
   ```

4. **IMPORTANT - Review cassettes before committing**:
   ```r
   # Use the helper function to check for sensitive data
   source("tests/testthat/helper-vcr.R")
   check_cassette_safety("ct_env_fate_single.yml")

   # Or check all cassettes
   cassettes <- list.files("tests/testthat/fixtures", pattern = "\\.yml$")
   sapply(cassettes, check_cassette_safety)
   ```

   Manually verify that actual API keys are replaced with `<<<API_KEY>>>`

### Re-recording cassettes from production

When you need to update cassettes (API changes, new test cases, etc.):

```r
# Load helper functions
source("tests/testthat/helper-vcr.R")

# Option 1: Delete all cassettes
delete_all_cassettes()

# Option 2: Delete specific cassettes
delete_cassettes("ct_env_fate")

# Option 3: Delete manually
unlink("tests/testthat/fixtures/*.yml")

# Then run tests with your API key to re-record
Sys.setenv(ctx_api_key = "YOUR_REAL_API_KEY")
devtools::test()
```

### Running tests without API key

Once cassettes are recorded, you can run tests without a real API key:
```r
# Unset or use placeholder
Sys.setenv(ctx_api_key = "test_api_key_placeholder")

# Tests will use recorded cassettes
devtools::test()
```

## Test Organization

### File Structure

```
tests/
├── testthat.R              # Entry point for R CMD check
├── testthat/
│   ├── setup.R             # Global test setup, vcr configuration
│   ├── helper.R            # Helper functions for tests
│   ├── test-ct_env_fate.R  # Tests for ct_env_fate function
│   └── fixtures/           # vcr cassettes (recorded HTTP interactions)
│       └── *.yml
```

### Test File Naming

- Test files must start with `test-`
- Name pattern: `test-<function_name>.R`
- Example: `test-ct_env_fate.R` tests the `ct_env_fate()` function

### Helper Functions

Common helper functions are available in `helper.R`:

- `skip_if_no_api_key()`: Skip test if API key not available
- `skip_if_no_base_url()`: Skip test if base URL not set
- `is_ci()`: Check if running in CI environment
- `get_test_dtxsids()`: Get standard test DTXSIDs

VCR management functions are available in `helper-vcr.R`:

- `delete_all_cassettes()`: Delete all cassettes to force production re-recording
- `delete_cassettes(pattern)`: Delete cassettes matching a pattern
- `list_cassettes()`: Show all recorded cassettes
- `check_cassette_safety(cassette_name)`: Verify cassette has no sensitive data

## Writing New Tests

### Basic test structure

```r
test_that("descriptive test name", {
  vcr::use_cassette("cassette_name", {
    result <- your_function("arg")

    expect_type(result, "list")
    expect_true(length(result) > 0)
  })
})
```

### Test expectations (testthat 3)

Common expectations:
- `expect_equal(x, y)`: x equals y
- `expect_true(x)`: x is TRUE
- `expect_false(x)`: x is FALSE
- `expect_error(expr, regexp)`: expr throws error matching regexp
- `expect_warning(expr, regexp)`: expr produces warning
- `expect_type(x, type)`: x has type
- `expect_length(x, n)`: x has length n
- `expect_no_error(expr)`: expr doesn't throw error

### Skipping tests

```r
test_that("expensive test", {
  skip_if_no_api_key()
  skip_if(Sys.getenv("RUN_SLOW_TESTS") != "true", "Slow test")

  # test code...
})
```

## Environment Variables

Tests use these environment variables:

- `ctx_api_key`: CompTox API key
- `ctx_burl`: API base URL (default: https://api-ccte.epa.gov/)
- `batch_limit`: Batch size for API requests (default: 100)
- `run_verbose`: Enable verbose output (default: FALSE for tests)
- `run_debug`: Enable debug mode (default: FALSE for tests)
- `RUN_SLOW_TESTS`: Set to "true" to run slow/expensive tests
- `CI`: Set to "true" in CI environments

## Continuous Integration

When setting up CI (GitHub Actions, etc.):

### Recommended approach: Use cassettes in CI

1. **Locally**: Record cassettes from production with your API key
2. **Commit**: Add cassettes to git repository after reviewing for sensitive data
3. **CI**: Tests use committed cassettes (no API key needed in CI)

```yaml
# GitHub Actions example
- name: Run tests
  run: Rscript -e 'devtools::test()'
  # No API key needed - uses cassettes
```

### Alternative: Test against production in CI

If you want CI to always hit production (useful for integration testing):

1. Store API key as encrypted secret in CI platform
2. Set environment variable in CI config:
   ```yaml
   env:
     ctx_api_key: ${{ secrets.COMPTOX_API_KEY }}
   ```
3. Delete cassettes before tests to force production recording:
   ```yaml
   - name: Run tests against production
     run: |
       rm -f tests/testthat/fixtures/*.yml
       Rscript -e 'devtools::test()'
     env:
       ctx_api_key: ${{ secrets.COMPTOX_API_KEY }}
   ```

## Troubleshooting

### Test fails with "No cassettes found and no API key set"

This happens on the first test run or when cassettes have been deleted:

- **Solution**: Set your API key to record from production:
  ```r
  Sys.setenv(ctx_api_key = "YOUR_API_KEY")
  devtools::test()
  ```

### Test fails with "No CTX API key found"

This happens when running with an API key but it's not set correctly:

- **Solution**: Set API key: `Sys.setenv(ctx_api_key = "YOUR_KEY")`
- **Or**: Ensure cassettes exist and the test will use them instead

### Cassette contains real API key

If you find your actual API key in a cassette file:

- Check `setup.R` vcr configuration has proper `filter_sensitive_data`
- Delete the cassette: `delete_cassettes("cassette_name")`
- Re-record with API key filtering: `devtools::test()`
- Use `check_cassette_safety()` before committing

### Tests are slow

- Ensure vcr cassettes are being used
- Check that `use_cassette()` wraps API calls
- Verify cassette files exist in `fixtures/`

### vcr error: "Could not find cassette"

- Run tests with valid API key to record cassettes
- Check cassette name matches `use_cassette()` call

## Best Practices

1. **Always use vcr for API calls**: Wrap API-calling code in `use_cassette()`
2. **Review cassettes before committing**: Ensure no sensitive data leaked
3. **Use descriptive test names**: Make failures easy to understand
4. **Test edge cases**: Empty inputs, errors, boundary conditions
5. **Keep tests isolated**: Each test should be independent
6. **Use helper functions**: Don't repeat setup code
7. **Document complex tests**: Add comments explaining what's being tested

## Example: Testing a New Function

```r
# In tests/testthat/test-ct_new_function.R

test_that("ct_new_function works with valid input", {
  vcr::use_cassette("new_function_valid", {
    result <- ct_new_function("DTXSID7020182")

    expect_type(result, "list")
    expect_true(length(result) > 0)
  })
})

test_that("ct_new_function handles errors", {
  expect_error(
    ct_new_function(NULL),
    "must be a character"
  )
})

test_that("ct_new_function processes multiple inputs", {
  vcr::use_cassette("new_function_multiple", {
    result <- ct_new_function(get_test_dtxsids())

    expect_type(result, "list")
    expect_gte(length(result), length(get_test_dtxsids()))
  })
})
```

## Additional Resources

- [testthat documentation](https://testthat.r-lib.org/)
- [vcr package documentation](https://docs.ropensci.org/vcr/)
- [R Packages book - Testing chapter](https://r-pkgs.org/testing-basics.html)
