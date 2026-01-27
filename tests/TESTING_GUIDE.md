# ComptoxR Testing Guide

## Overview

The ComptoxR testing framework has been completely overhauled to generate tests based on actual function signatures and return types extracted from the source code, rather than using generic templates.

## Key Improvements

### Before (Old System)
- ❌ All tests assumed functions return tibbles
- ❌ All tests used generic "query" parameter with DTXSID
- ❌ Didn't leverage function documentation or examples
- ❌ Many tests failed because of incorrect assumptions

### After (New System)
- ✅ Extracts actual return types from `@return` documentation
- ✅ Uses correct parameter names from function signatures
- ✅ Leverages `@examples` from documentation when available
- ✅ Validates against appropriate return types (tibble, character, list, image, etc.)
- ✅ Handles different parameter types (query, list_name, dtxsid, etc.)
- ✅ Only generates batch tests for functions that support batching

## Architecture

### 1. Metadata Extraction (`helper-function-metadata.R`)

Extracts comprehensive metadata from R source files:

```r
metadata <- extract_function_metadata("R/ct_hazard.R")
# Returns:
# - Function name
# - Parameters (names, defaults, required/optional)
# - Return type (tibble, character, list, image, etc.)
# - Examples from documentation
# - generic_request configuration
```

### 2. Test Generation (`helper-test-generator-v2.R`)

Generates appropriate tests based on metadata:

- **Basic functionality test**: Uses correct parameter and validates return type
- **Example-based test**: Uses example from function documentation
- **Batch test**: Only for functions that support batching
- **Error handling test**: Validates graceful handling of invalid input

### 3. Test Runner (`generate_tests_v2.R`)

Main script to generate all tests:

```r
# Generate all tests
source("tests/generate_tests_v2.R")
generate_tests_with_metadata()

# Generate specific tests
generate_tests_with_metadata(c("ct_hazard", "ct_list"))

# Preview without writing
preview_test("ct_hazard")

# Regenerate with overwrite
regenerate_function_tests(c("ct_hazard"), overwrite = TRUE)
```

## Return Type Detection

The system automatically detects return types from `@return` documentation:

| Documentation Keywords | Detected Type |
|------------------------|---------------|
| "tibble", "tbl_df", "data.frame" | `tibble` |
| "character vector" | `character` |
| "list" | `list` |
| "image", "raw", "magick" | `image` |
| "logical", "boolean" | `logical` |
| "numeric", "integer" | `numeric` |

### Example Return Type Validation

**Tibble:**
```r
expect_s3_class(result, "tbl_df")
expect_true(ncol(result) > 0 || nrow(result) == 0)
```

**Character:**
```r
expect_type(result, "character")
expect_true(is.character(result))
```

**List:**
```r
expect_type(result, "list")
expect_true(is.list(result))
```

**Image:**
```r
expect_true(
  inherits(result, "magick-image") ||
  is.raw(result) ||
  is.character(result)
)
```

## Parameter Type Detection

The system determines appropriate test inputs based on parameter names:

| Parameter Name | Test Input Used |
|----------------|-----------------|
| `query` (general endpoint) | DTXSID: "DTXSID7020182" |
| `query` (list endpoint) | List name: "PRODWATER" |
| `list_name` | List name: "PRODWATER" |
| `dtxsid` | DTXSID: "DTXSID7020182" |
| `chemicals` | Chemical name: "benzene" |
| `casrn` | CAS RN: "50-00-0" |
| `formula` | Formula: "C6H6" |
| `smiles` | SMILES: "c1ccccc1" |

## Example Generated Tests

### Example 1: ct_hazard (Returns Tibble)

```r
# Tests for ct_hazard
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results

test_that("ct_hazard works with single input", {
    vcr::use_cassette("ct_hazard_single", {
        result <- ct_hazard(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_hazard works with documented example", {
    vcr::use_cassette("ct_hazard_example", {
        result <- ct_hazard(query = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_hazard handles batch requests", {
    vcr::use_cassette("ct_hazard_batch", {
        result <- ct_hazard(query = c("DTXSID7020182", "DTXSID5032381",
            "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_hazard handles invalid input gracefully", {
    vcr::use_cassette("ct_hazard_error", {
        result <- suppressWarnings(ct_hazard(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) &&
            nrow(result) == 0) || (is.character(result) && length(result) ==
            0) || (is.list(result) && length(result) == 0))
    })
})
```

### Example 2: ct_list (Returns Character Vector)

```r
# Tests for ct_list
# Generated using metadata-based test generator
# Return type: character
# Returns a character vector (if extract_dtxsids=TRUE) or list of results (if FALSE)

test_that("ct_list works with single input", {
    vcr::use_cassette("ct_list_single", {
        result <- ct_list(list_name = "PRODWATER")
        {
            expect_type(result, "character")
            expect_true(is.character(result))
        }
    })
})

test_that("ct_list works with documented example", {
    vcr::use_cassette("ct_list_example", {
        result <- ct_list(list_name = c("PRODWATER", "CWA311HS"),
            extract_dtxsids = TRUE)
        expect_true(!is.null(result))
    })
})
```

### Example 3: ct_chemical_file_image (Returns Image)

```r
# Tests for ct_chemical_file_image
# Generated using metadata-based test generator
# Return type: image
# Returns image data (raw bytes or magick image object)

test_that("ct_chemical_file_image works with single input", {
    vcr::use_cassette("ct_chemical_file_image_single", {
        result <- ct_chemical_file_image(dtxsid = "DTXSID7020182")
        {
            expect_true(inherits(result, "magick-image") || is.raw(result) ||
                is.character(result))
        }
    })
})

test_that("ct_chemical_file_image works with documented example", {
    vcr::use_cassette("ct_chemical_file_image_example", {
        result <- ct_chemical_file_image(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})
```

### Example 4: ct_lists_all (No Parameters)

```r
# Tests for ct_lists_all
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble of results (or nested list if coerce=TRUE)

test_that("ct_lists_all works without parameters", {
    vcr::use_cassette("ct_lists_all_basic", {
        result <- ct_lists_all()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})
```

## Migration Path

### Regenerating All Tests

**WARNING**: This will overwrite existing test files!

```r
# Backup existing tests first
system("cp -r tests/testthat tests/testthat.backup")

# Regenerate all tests
source("tests/generate_tests_v2.R")
generate_tests_with_metadata(overwrite = TRUE)
```

### Selective Regeneration

Regenerate specific functions while keeping others:

```r
# Regenerate only problematic functions
source("tests/generate_tests_v2.R")
regenerate_function_tests(c(
  "ct_chemical_file_image",
  "ct_list",
  "ct_lists_all"
))
```

### Manual Review

After generation, review tests for:

1. **Correct test inputs**: Ensure the test data makes sense for the function
2. **Return type validation**: Verify expectations match actual behavior
3. **API cassettes**: Ensure VCR cassettes are recorded correctly
4. **Edge cases**: Add additional tests for special cases not covered

## Adding Custom Test Inputs

To add custom test inputs for specific functions:

```r
# In generate_tests_v2.R, modify get_standard_test_inputs()

get_standard_test_inputs <- function() {
  list(
    # ... existing inputs ...

    # Add custom input type
    my_custom_param = list(
      single = "custom_value",
      batch = c("value1", "value2"),
      invalid = "INVALID"
    )
  )
}

# Then in determine_test_input_type(), add mapping:
if (param_name == "my_param") {
  return("my_custom_param")
}
```

## Workflow

1. **Write/modify function** in `R/`
2. **Add documentation**: Ensure `@param`, `@return`, and `@examples` are complete
3. **Generate tests**:
   ```r
   source("tests/generate_tests_v2.R")
   regenerate_function_tests("my_new_function")
   ```
4. **Review generated test**: Check it matches function behavior
5. **Set API key**: `Sys.setenv(ctx_api_key = 'YOUR_KEY')`
6. **Record cassettes**: `devtools::test()`
7. **Verify tests pass**: `devtools::check()`
8. **Commit**: Tests + cassettes

## Benefits

1. **Accuracy**: Tests match actual function behavior
2. **Maintainability**: Tests auto-update when documentation changes
3. **Coverage**: Appropriate tests for each function type
4. **Consistency**: Standardized test structure across package
5. **Documentation**: Tests serve as usage examples

## Future Enhancements

- [ ] Auto-detect example values from function defaults
- [ ] Generate property-based tests for appropriate functions
- [ ] Extract and test expected columns from API schemas
- [ ] Integration with API documentation
- [ ] Automated cassette validation
