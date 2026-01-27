# Migration to New Testing System

## Overview

This document guides you through migrating from the old template-based testing system to the new metadata-driven system.

## What Changed?

### Old System (`generate_tests.R` + `helper-test-generator.R`)

**Problems:**
- Hardcoded assumptions about return types (always expected tibbles)
- Generic test inputs didn't match function signatures
- Manual function signature mapping in `function_signatures` list
- No leverage of function documentation or examples
- Batch tests generated for all functions regardless of support

**Files:**
- `tests/generate_tests.R` - Old generator script
- `tests/testthat/helper-test-generator.R` - Old template system

### New System (`generate_tests_v2.R` + helpers)

**Improvements:**
- Extracts metadata directly from source files
- Detects return types from `@return` documentation
- Uses examples from `@examples` when available
- Determines appropriate test inputs based on parameter names
- Only generates batch tests for functions that support batching

**Files:**
- `tests/generate_tests_v2.R` - New generator script
- `tests/testthat/helper-function-metadata.R` - Metadata extraction
- `tests/testthat/helper-test-generator-v2.R` - Metadata-based test generation

## Migration Steps

### Step 1: Backup Existing Tests

```bash
# Backup all existing tests
cp -r tests/testthat tests/testthat.backup
cp -r tests/fixtures tests/fixtures.backup
```

### Step 2: Review Function Documentation

Before generating tests, ensure all functions have proper documentation:

```r
#' Function description
#'
#' @param query A single DTXSID or vector of DTXSIDs
#' @return Returns a tibble with results  # <-- IMPORTANT: Be specific!
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard(query = "DTXSID7020182")  # <-- IMPORTANT: Realistic example!
#' }
ct_hazard <- function(query) {
  # ...
}
```

**Key documentation requirements:**
1. `@return` should clearly state return type (tibble, character vector, list, etc.)
2. `@examples` should show realistic usage
3. `@param` should indicate if parameters are optional

### Step 3: Generate New Tests

#### Option A: Generate All Tests (Recommended for New Projects)

```r
# Load the new system
source("tests/generate_tests_v2.R")

# Generate all tests (won't overwrite by default)
results <- generate_tests_with_metadata()

# Review the summary
print(results)
```

#### Option B: Incremental Migration (Recommended for Existing Projects)

```r
# Start with a few functions
source("tests/generate_tests_v2.R")

# Preview before generating
preview_test("ct_hazard")
preview_test("ct_list")

# Generate for specific functions
results <- generate_tests_with_metadata(
  functions_to_test = c("ct_hazard", "ct_list", "ct_chemical_file_image"),
  overwrite = TRUE
)
```

#### Option C: Generate for Functions Without Tests

```r
source("tests/generate_tests_v2.R")

# Get all functions
all_metadata <- extract_all_metadata("R")
all_functions <- names(all_metadata)

# Find functions without tests
existing_tests <- list.files("tests/testthat", pattern = "^test-.*\\.R$")
tested_functions <- gsub("^test-|\\.R$", "", existing_tests)

# Functions needing tests
needs_tests <- setdiff(all_functions, tested_functions)

if (length(needs_tests) > 0) {
  cat("Generating tests for", length(needs_tests), "functions without tests\n")
  generate_tests_with_metadata(functions_to_test = needs_tests)
}
```

### Step 4: Review Generated Tests

Review each generated test file for:

1. **Correct parameter usage**: Does the test use the right parameter name?
2. **Appropriate test data**: Is "DTXSID7020182" appropriate, or does it need a different value?
3. **Return type validation**: Does the function actually return what's being tested?
4. **Missing edge cases**: Are there special cases that need additional tests?

Example review:

```r
# Generated test
test_that("ct_chemical_file_image works with single input", {
  vcr::use_cassette("ct_chemical_file_image_single", {
    result <- ct_chemical_file_image(dtxsid = "DTXSID7020182")
    expect_true(
      inherits(result, "magick-image") ||
      is.raw(result) ||
      is.character(result)
    )
  })
})

# Review questions:
# ✓ Is "DTXSID7020182" a valid DTXSID for this function?
# ✓ Does this function return image data?
# ✓ Are the expectations correct?
# ? Should we test specific image properties?
```

### Step 5: Record VCR Cassettes

```r
# Set your API key
Sys.setenv(ctx_api_key = "YOUR_API_KEY")
Sys.setenv(chemi_burl = "YOUR_CHEMI_URL")  # If using chemi functions

# Run tests to record cassettes
devtools::test()

# Or test specific files
testthat::test_file("tests/testthat/test-ct_hazard.R")
```

### Step 6: Validate Tests Pass

```r
# Run all tests
devtools::check()

# Check specific tests
devtools::test(filter = "ct_hazard")

# Check coverage
covr::package_coverage()
```

### Step 7: Clean Up Old System (Optional)

After successful migration:

```bash
# Rename old files for reference
mv tests/generate_tests.R tests/generate_tests.OLD.R
mv tests/testthat/helper-test-generator.R tests/testthat/helper-test-generator.OLD.R

# Or remove if confident
rm tests/generate_tests.R
rm tests/testthat/helper-test-generator.R
```

## Common Issues & Solutions

### Issue 1: Wrong Return Type Detected

**Problem:** Function returns list but detected as tibble

**Solution:** Update `@return` documentation

```r
# Before
#' @return Results from the API

# After
#' @return Returns a list of results (use tidy=TRUE for tibble)
```

Then regenerate:

```r
regenerate_function_tests("my_function")
```

### Issue 2: Wrong Test Input Type

**Problem:** Function uses `list_name` but test uses DTXSID

**Solution:** Add mapping in `determine_test_input_type()`

Edit `tests/testthat/helper-test-generator-v2.R`:

```r
determine_test_input_type <- function(param_name, metadata) {
  # Add your custom mapping
  if (param_name == "my_special_param") {
    return("my_custom_input_type")
  }

  # ... rest of function
}
```

Add input to `get_standard_test_inputs()`:

```r
get_standard_test_inputs <- function() {
  list(
    # ... existing ...

    my_custom_input_type = list(
      single = "appropriate_value",
      batch = c("value1", "value2"),
      invalid = "INVALID"
    )
  )
}
```

### Issue 3: Example Parsing Fails

**Problem:** Complex example doesn't parse correctly

**Solution:** Simplify example or skip auto-generation

```r
# Keep example simple for auto-generation
#' @examples
#' \dontrun{
#' ct_hazard(query = "DTXSID7020182")
#' }

# Complex examples can be in separate section
#' @section Advanced Usage:
#' ```r
#' # Complex multi-step example
#' dtxsids <- ct_list("PRODWATER")
#' results <- ct_hazard(dtxsids)
#' ```
```

### Issue 4: Batch Test Generated for Non-Batch Function

**Problem:** Function doesn't support batching but test generated

**Solution:** The system checks `batch_limit` and `method`. If incorrect, update source:

```r
# In function definition
generic_request(
  query = query,
  endpoint = "my/endpoint",
  method = "GET",
  batch_limit = 1  # <-- Set to 1 for non-batch functions
)
```

## Comparison Examples

### Before vs After: ct_chemical_file_image

**Before (template-based):**
```r
test_that("ct_chemical_file_image works with valid input", {
  vcr::use_cassette("ct_chemical_file_image_query", {
    result <- ct_chemical_file_image(query = "DTXSID7020182")
    {
      expect_s3_class(result, "tbl_df")  # ❌ WRONG! Returns image
      expect_true(ncol(result) > 0)      # ❌ WRONG! Not a tibble
    }
  })
})
```

**After (metadata-based):**
```r
test_that("ct_chemical_file_image works with single input", {
  vcr::use_cassette("ct_chemical_file_image_single", {
    result <- ct_chemical_file_image(dtxsid = "DTXSID7020182")  # ✅ Correct param name
    {
      expect_true(
        inherits(result, "magick-image") ||
        is.raw(result) ||
        is.character(result)  # ✅ Correct image validation
      )
    }
  })
})
```

### Before vs After: ct_list

**Before (template-based):**
```r
test_that("ct_list works with valid input", {
  vcr::use_cassette("ct_list_list_name", {
    result <- ct_list(list_name = "PRODWATER")
    {
      expect_s3_class(result, "tbl_df")  # ❌ WRONG! Returns character vector
      expect_true(ncol(result) > 0)      # ❌ WRONG! Not a tibble
    }
  })
})
```

**After (metadata-based):**
```r
test_that("ct_list works with single input", {
  vcr::use_cassette("ct_list_single", {
    result <- ct_list(list_name = "PRODWATER")
    {
      expect_type(result, "character")  # ✅ Correct type
      expect_true(is.character(result)) # ✅ Correct validation
    }
  })
})
```

## Rollback Plan

If you need to rollback to the old system:

```bash
# Restore backup
rm -rf tests/testthat
cp -r tests/testthat.backup tests/testthat

# Use old generator
source("tests/generate_tests.R")
generate_tests()
```

## Next Steps

1. Complete migration of all test files
2. Review and enhance generated tests with edge cases
3. Update CI/CD pipelines if needed
4. Document any custom test patterns for your package
5. Consider contributing improvements back to the testing system

## Questions?

See `tests/TESTING_GUIDE.md` for detailed documentation on the new system.
