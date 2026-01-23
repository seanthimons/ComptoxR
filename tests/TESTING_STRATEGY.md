# Testing Strategy for ComptoxR

## Current Status
- **Current Coverage: 7.06%**
- **Target Coverage: >90%**
- **Existing Test Files: 4**
  - `test-generic_request.R` - Core template testing
  - `test-generic_chemi_request.R` - Chemi template testing
  - `test-clean_unicode.R` - Utility testing
  - `test-ctx_dashboard.R` - Dashboard testing

## Coverage Gaps

Based on the current codebase structure, here are the main areas missing test coverage:

### 1. API Wrapper Functions (High Priority)
**Impact on coverage: ~40-50%**

#### CT Functions (21 functions)
Most ct_* functions are simple wrappers around `generic_request()`. Test coverage needs:
- Basic functionality (single query)
- Batch processing (multiple queries)
- Error handling (invalid inputs)
- Edge cases (empty results, NULL inputs)

**Functions needing tests:**
- `ct_bioactivity()` and all related endpoint-specific functions (~90 auto-generated functions)
- `ct_cancer()`
- `ct_classify()`
- `ct_compound_in_list()`
- `ct_details()`
- `ct_env_fate()`
- `ct_functional_use()`
- `ct_genotox()`
- `ct_ghs()`
- `ct_hazard()`
- `ct_list()`
- `ct_lists_all()`
- `ct_properties()`
- `ct_related()`
- `ct_search()`
- `ct_similar()`
- `ct_skin_eye()`
- `ct_synonym()`
- `ct_test()`

#### Chemi Functions (12 functions)
Wrappers around `generic_chemi_request()`:
- `chemi_classyfire()`
- `chemi_cluster()`
- `chemi_cluster_sim_list()`
- `chemi_hazard()`
- `chemi_predict()`
- `chemi_resolver()`
- `chemi_rq()`
- `chemi_safety()`
- `chemi_safety_section()`
- `chemi_search()`
- `chemi_toxprint()`

### 2. Utility Functions (Medium Priority)
**Impact on coverage: ~10-15%**

- `extract_cas()` - CAS number extraction
- `extract_formulas()` - Formula parsing
- `extract_mixture()` - Mixture detection
- `is_cas()` - CAS validation
- `as_cas()` - CAS formatting
- `util_classyfire()` - Classification utilities
- `get_ct_image()` - Image retrieval

### 3. Server Configuration (Low Priority)
**Impact on coverage: ~5%**

- `ctx_server()` - Server switching
- `chemi_server()` - Chemi server config
- `eco_server()` - ECOTOX config
- `epi_server()` - EPI Suite config

### 4. Package Initialization (Low Priority)
**Impact on coverage: ~5-10%**

- `.onLoad()` - Package loading logic
- `.onAttach()` - Startup messages
- Session-level caching initialization

### 5. Helper/Internal Functions (Medium Priority)
**Impact on coverage: ~10-15%**

- `tidy_results()` - Result cleaning
- `batch_split()` - Batch management
- `build_request()` - Request construction
- Various internal helpers in `z_generic_request.R`

## Recommended Testing Strategy

### Phase 1: Quick Wins (Target: 40-50% coverage)
**Estimated Time: 2-3 hours**

1. **Test all simple wrapper functions using templates**
   ```r
   # Use the test generator helper
   source("tests/testthat/helper-test-generator.R")

   # For each ct_ function
   create_wrapper_test_file(
     fn_name = "ct_hazard",
     valid_input = list(query = "DTXSID7020182"),
     batch_input = c("DTXSID7020182", "DTXSID5032381"),
     invalid_input = "INVALID_ID",
     output_file = "tests/testthat/test-ct_hazard.R"
   )
   ```

2. **Record VCR cassettes for each function**
   - Run tests once with valid API key to record responses
   - Commit cassettes to repo
   - Future test runs use cassettes (no API key needed)

3. **Use mocking for consistent results**
   - Mock API responses for predictable testing
   - Avoid flakiness from API changes

### Phase 2: Utility Functions (Target: 60-70% coverage)
**Estimated Time: 2-4 hours**

1. **Test extraction functions**
   ```r
   test_that("extract_cas finds valid CAS numbers", {
     text <- "The compound 50-00-0 is formaldehyde"
     result <- extract_cas(text)
     expect_equal(result, "50-00-0")
   })
   ```

2. **Test validation functions**
   ```r
   test_that("is_cas correctly validates CAS numbers", {
     expect_true(is_cas("50-00-0"))
     expect_false(is_cas("50-00-1")) # Invalid checksum
     expect_false(is_cas("not-a-cas"))
   })
   ```

3. **Test formatting functions**
   - Test various input formats
   - Test edge cases (NULL, NA, empty strings)
   - Test unicode handling

### Phase 3: Integration Tests (Target: 75-85% coverage)
**Estimated Time: 3-5 hours**

1. **Test complete workflows**
   ```r
   test_that("complete hazard assessment workflow", {
     vcr::use_cassette("workflow_hazard", {
       # Search for chemical
       details <- ct_details("50-00-0")

       # Get DTXSID
       dtxsid <- details$dtxsid

       # Get hazard data
       hazard <- ct_hazard(dtxsid)

       expect_s3_class(hazard, "tbl_df")
       expect_true(nrow(hazard) > 0)
     })
   })
   ```

2. **Test cross-function compatibility**
   - Test piping results between functions
   - Test batch processing across functions
   - Test error propagation

### Phase 4: Edge Cases & Error Handling (Target: 85-95% coverage)
**Estimated Time: 2-4 hours**

1. **Test error conditions**
   - Invalid API keys
   - Network failures (mock)
   - Empty responses
   - Malformed responses
   - Rate limiting

2. **Test edge cases**
   - Empty vectors
   - NULL inputs
   - Very large batches
   - Special characters
   - Unicode handling

3. **Test parameter combinations**
   - Optional parameters
   - Parameter validation
   - Default values

### Phase 5: Final Push (Target: >90% coverage)
**Estimated Time: 2-3 hours**

1. **Identify remaining uncovered lines**
   ```r
   cov <- covr::package_coverage()
   print(cov)
   covr::report(cov)  # Opens interactive HTML report
   ```

2. **Write targeted tests for uncovered code**
   - Focus on conditional branches
   - Test error handling paths
   - Test internal helper functions

3. **Clean up and document**
   - Remove redundant tests
   - Improve test organization
   - Document test fixtures

## Testing Tools & Helpers

### VCR Configuration
Tests use `vcr` to record/replay API responses:

```r
# Delete all cassettes to re-record
source("tests/testthat/helper-vcr.R")
delete_all_cassettes()

# Delete specific cassettes
delete_cassettes("ct_hazard")

# List all cassettes
list_cassettes()

# Check cassette safety (no API keys leaked)
check_cassette_safety("cassette_name.yml")
```

### Test Template Generator
Use `helper-test-generator.R` to quickly generate tests:

```r
# Generate tests for a single function
create_wrapper_test_file(
  fn_name = "ct_hazard",
  valid_input = list(dtxsid = "DTXSID7020182"),
  batch_input = c("DTXSID7020182", "DTXSID5032381"),
  invalid_input = "INVALID_ID",
  output_file = "tests/testthat/test-ct_hazard.R"
)

# Generate tests for all ct_ functions (skips existing)
generate_all_ct_tests()
```

### Debug Mode Testing
Test request construction without hitting APIs:

```r
test_that("ct_hazard constructs request correctly", {
  Sys.setenv(run_debug = "TRUE")
  on.exit(Sys.setenv(run_debug = "FALSE"))

  output <- capture_output(
    ct_hazard("DTXSID7020182")
  )

  expect_match(output, "POST")
  expect_match(output, "hazard")
  expect_match(output, "DTXSID7020182")
})
```

### Mocking with testthat
Mock API responses for consistent testing:

```r
test_that("ct_hazard handles response correctly", {
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
      result <- ct_hazard("DTXSID7020182")
      expect_s3_class(result, "tbl_df")
    }
  )
})
```

## Best Practices

### 1. Test Organization
- One test file per exported function (or logical group)
- Use descriptive test names: `test_that("function_name does X when Y")`
- Group related tests with context

### 2. Test Data
- Use consistent test identifiers across tests:
  - DTXSID: `DTXSID7020182` (Formaldehyde)
  - CAS: `50-00-0` (Formaldehyde)
  - SMILES: `C=O` (Formaldehyde)
- Create fixtures for complex test data

### 3. VCR Cassettes
- Use descriptive cassette names
- Check cassettes before committing (no API keys!)
- Keep cassettes minimal (avoid recording large responses)
- Re-record cassettes when API changes

### 4. Coverage Goals
- **Priority 1 (Must have ≥95% coverage):**
  - `generic_request()` - Core template
  - `generic_chemi_request()` - Chemi template
  - Critical utility functions (CAS validation, extraction)

- **Priority 2 (Target ≥80% coverage):**
  - All exported wrapper functions
  - Public utility functions
  - Error handling paths

- **Priority 3 (Target ≥60% coverage):**
  - Internal helpers
  - Package initialization
  - Server configuration

### 5. CI/CD Integration
- Run tests on every commit
- Fail builds if coverage drops below 80%
- Generate coverage reports
- Cache VCR cassettes in CI

## Running Tests

```r
# Run all tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-ct_hazard.R")

# Run with coverage
cov <- covr::package_coverage()
print(cov)

# Generate HTML coverage report
covr::report(cov)

# Run tests with detailed output
devtools::test(reporter = "progress")
```

## Troubleshooting

### Tests failing with "No API key"
- Set API key: `Sys.setenv(ctx_api_key = "YOUR_KEY")`
- Or use VCR cassettes (recorded responses)
- Or mock API responses

### Tests failing with network errors
- Check if cassettes exist
- Re-record cassettes if API changed
- Use mocking for offline testing

### Coverage not improving
- Check which lines are uncovered: `covr::report(cov)`
- Focus on branches and error paths
- Test edge cases and error conditions
- Ensure tests actually execute the code paths

### VCR cassettes contain sensitive data
- Use `check_cassette_safety()` helper
- Configure VCR to filter sensitive data
- Re-record cassettes with filtering enabled

## Expected Timeline

| Phase | Coverage Target | Estimated Time | Priority |
|-------|----------------|----------------|----------|
| Phase 1 | 40-50% | 2-3 hours | High |
| Phase 2 | 60-70% | 2-4 hours | High |
| Phase 3 | 75-85% | 3-5 hours | Medium |
| Phase 4 | 85-95% | 2-4 hours | Medium |
| Phase 5 | >90% | 2-3 hours | Low |
| **Total** | **>90%** | **11-19 hours** | - |

## Next Steps

1. **Immediate (Today):**
   - Run `generate_all_ct_tests()` to create test file templates
   - Record VCR cassettes for top 5 most-used functions
   - Get coverage to 30-40%

2. **Short-term (This Week):**
   - Complete Phase 1 and Phase 2
   - Set up CI to run tests automatically
   - Reach 60-70% coverage

3. **Medium-term (This Month):**
   - Complete Phase 3 and Phase 4
   - Reach 85%+ coverage
   - Document all test patterns

4. **Long-term (Ongoing):**
   - Maintain >80% coverage
   - Add tests for new functions
   - Keep VCR cassettes updated
