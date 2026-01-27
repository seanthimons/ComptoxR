# Testing Infrastructure Changelog

## [2.0.0] - 2026-01-23 - Metadata-Based Testing System

### 🎉 Major Overhaul

Complete rewrite of the testing infrastructure to use metadata-driven test generation instead of generic templates.

### Added

- **`helper-function-metadata.R`** - Extracts comprehensive metadata from R source files
  - Function signatures and parameters
  - Return types from `@return` documentation
  - Examples from `@examples` sections
  - `generic_request` configuration analysis

- **`helper-test-generator-v2.R`** - Metadata-based test generation
  - Return type-specific expectations (tibble, character, list, image, etc.)
  - Parameter-aware test input selection
  - Example-based test generation
  - Smart batch test detection
  - Improved error handling tests

- **`generate_tests_v2.R`** - Enhanced test generation script
  - `generate_tests_with_metadata()` - Main generation function
  - `preview_test()` - Preview tests without writing
  - `regenerate_function_tests()` - Selective regeneration
  - Detailed progress reporting and summaries

- **`TESTING_GUIDE.md`** - Comprehensive documentation
  - System overview and architecture
  - Return type detection
  - Parameter type handling
  - Migration instructions
  - Example generated tests
  - Best practices

- **`MIGRATION.md`** - Migration guide from old system
  - Step-by-step migration process
  - Common issues and solutions
  - Before/after comparisons
  - Rollback procedures

### Changed

- **Test validation** - Now validates against actual return types instead of assuming all functions return tibbles
- **Test inputs** - Uses appropriate test data based on parameter names (DTXSID, list_name, chemicals, etc.)
- **Batch testing** - Only generates batch tests for functions that support batching (checks `batch_limit` and `method`)

### Deprecated

- **`generate_tests.R`** (old) - Replaced by `generate_tests_v2.R`
- **`helper-test-generator.R`** (old) - Replaced by `helper-test-generator-v2.R` and `helper-function-metadata.R`

### Fixed

- ❌ **Fixed**: Tests for `ct_chemical_file_image` expecting tibble instead of image data
- ❌ **Fixed**: Tests for `ct_list` expecting tibble instead of character vector
- ❌ **Fixed**: Tests using wrong parameter names (e.g., `query` instead of `list_name`)
- ❌ **Fixed**: Batch tests generated for non-batch functions
- ❌ **Fixed**: Generic test inputs not matching function-specific requirements

## Problems with Old System (Pre-2.0.0)

### Template-Based Limitations

The old system used hardcoded templates with several critical flaws:

1. **Wrong return type assumptions**
   ```r
   # Old system always expected tibbles
   expect_s3_class(result, "tbl_df")  # WRONG for many functions!
   ```

2. **Wrong parameter usage**
   ```r
   # Old system used generic "query" parameter
   ct_list(query = "PRODWATER")  # WRONG! Should be list_name
   ```

3. **Manual maintenance required**
   ```r
   # Required hardcoded function signature mapping
   function_signatures <- list(
     ct_hazard = "query_single",
     ct_list = "list_name",
     # ... manually maintained list
   )
   ```

4. **Didn't use documentation**
   - Ignored `@examples` from roxygen
   - Didn't parse `@return` for return types
   - Generic test inputs for all functions

## Migration Impact

### Files Changed

| File | Status | Action |
|------|--------|--------|
| `generate_tests.R` | ⚠️ Deprecated | Add deprecation notice, keep for compatibility |
| `helper-test-generator.R` | ⚠️ Deprecated | Add deprecation notice, keep for compatibility |
| `generate_tests_v2.R` | ✅ New | Primary test generator |
| `helper-function-metadata.R` | ✅ New | Metadata extraction |
| `helper-test-generator-v2.R` | ✅ New | Metadata-based generation |
| `TESTING_GUIDE.md` | ✅ New | Comprehensive documentation |
| `MIGRATION.md` | ✅ New | Migration guide |
| `README.md` | ✅ Updated | Add new system overview |

### Test Files

Existing test files are **not automatically updated**. Users should:

1. Review existing tests for accuracy
2. Selectively regenerate problematic tests using new system
3. Gradually migrate all tests over time

### Breaking Changes

- **None** - Old system still works for backwards compatibility
- New system is opt-in via `generate_tests_v2.R`
- Existing tests continue to function as-is

## Usage Examples

### Before (Old System)

```r
# Manual function signature mapping
source("tests/generate_tests.R")
generate_tests(c("ct_hazard"))

# Generated wrong tests:
# - ct_list expecting tibble (returns character)
# - ct_chemical_file_image expecting tibble (returns image)
# - Wrong parameter names
```

### After (New System)

```r
# Automatic metadata extraction
source("tests/generate_tests_v2.R")

# Preview before generating
preview_test("ct_hazard")

# Generate correct tests based on actual function
regenerate_function_tests("ct_hazard")

# Results:
# - Correct return type validation
# - Correct parameter names
# - Uses examples from documentation
# - Only generates applicable tests
```

## Return Type Support

The new system correctly handles:

| Return Type | Validation |
|-------------|------------|
| tibble | `expect_s3_class(result, "tbl_df")` |
| character | `expect_type(result, "character")` |
| list | `expect_type(result, "list")` |
| image | `expect_true(inherits(result, "magick-image") \|\| is.raw(result))` |
| logical | `expect_type(result, "logical")` |
| numeric | `expect_type(result, "double")` |

## Future Enhancements

Potential improvements for future versions:

- [ ] Auto-detect example values from function defaults
- [ ] Property-based testing generation
- [ ] API schema integration for column validation
- [ ] Automated cassette validation
- [ ] Test quality scoring
- [ ] Incremental test updates when functions change
- [ ] Integration with CI/CD for automatic test generation

## Acknowledgments

This overhaul addresses long-standing issues where automatically generated tests didn't match actual function behavior, leading to test failures and maintenance burden. The new metadata-based approach ensures tests accurately reflect function signatures and return types.
