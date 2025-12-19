# Quick Start Guide - Testing ComptoxR

## First Time Setup (Recording from Production)

```r
# 1. Set your API key
Sys.setenv(ctx_api_key = "YOUR_REAL_API_KEY")

# 2. Run tests - this will hit production and record cassettes
devtools::test()

# 3. Check cassettes for sensitive data
source("tests/testthat/helper-vcr.R")
list_cassettes()
check_cassette_safety("ct_env_fate_single.yml")
```

## Running Tests (After Initial Setup)

```r
# Run all tests (uses cached cassettes, no API key needed)
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-ct_env_fate.R")
```

## Updating Tests (Re-record from Production)

```r
# Load helper functions
source("tests/testthat/helper-vcr.R")

# Delete cassettes
delete_all_cassettes()  # All cassettes
# OR
delete_cassettes("ct_env_fate")  # Specific pattern

# Set API key and re-run tests
Sys.setenv(ctx_api_key = "YOUR_REAL_API_KEY")
devtools::test()
```

## Key Points

- **First run ALWAYS hits production** (requires API key)
- **Subsequent runs use cassettes** (no API key needed)
- **Always review cassettes** before committing to git
- **Delete cassettes** to force re-recording from production

## Common Commands

```r
# List all cassettes
source("tests/testthat/helper-vcr.R")
list_cassettes()

# Check cassette safety
check_cassette_safety("cassette_name.yml")

# View cassette location
list.files("tests/testthat/fixtures", full.names = TRUE)

# Run with test coverage
covr::package_coverage()
```

## Need Help?

See `tests/README.md` for detailed documentation.
