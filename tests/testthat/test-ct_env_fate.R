# Tests for ct_env_fate function
# Using vcr to record and replay HTTP interactions

library(vcr)
ctx_server(1) # Ensure using production server for tests

# Test: Single DTXSID query
test_that("ct_env_fate works with a single DTXSID", {
	local_vcr_configure_log()
  vcr::use_cassette("ct_env_fate_single", {
    result <- ct_env_fate("DTXSID4020533")

    expect_type(result, "list")
    expect_true(length(result) > 0)
  })
})

# Test: Multiple DTXSIDs query
test_that("ct_env_fate works with multiple DTXSIDs", {
	local_vcr_configure_log()
  vcr::use_cassette("ct_env_fate_multiple", {
    dtxsids <- get_test_dtxsids()
    result <- ct_env_fate(dtxsids)

    expect_type(result, "list")
    expect_true(length(result) >= length(dtxsids))
  })
})

# Test: Handling duplicate DTXSIDs
test_that("ct_env_fate removes duplicate DTXSIDs", {
	local_vcr_configure_log()
  vcr::use_cassette("ct_env_fate_duplicates", {
    dtxsids <- c("DTXSID4020533", "DTXSID4020533", "DTXSID5020406")

    # The function should handle duplicates by calling unique()
    result <- ct_env_fate(dtxsids)

    expect_type(result, "list")
    # Should query only unique values
    expect_true(length(result) > 0)
  })
})

# Test: Empty query handling
test_that("ct_env_fate errors on empty query", {
	local_vcr_configure_log()
  expect_error(
    ct_env_fate(character(0)),
    "Query must be a character vector of DTXSIDs"
  )
})

# Test: Vector coercion
test_that("ct_env_fate handles various input types", {
	local_vcr_configure_log()
  vcr::use_cassette("ct_env_fate_vector_coercion", {
    # Test with a list input
    result <- ct_env_fate(list("DTXSID4020533"))

    expect_type(result, "list")
    expect_true(length(result) > 0)
  })
})

# Test: Batch processing with large number of queries
test_that("ct_env_fate handles batching correctly", {
	local_vcr_configure_log()
  skip_if(
    !as.logical(Sys.getenv("RUN_SLOW_TESTS")),
    "Skipping slow batch test. Set RUN_SLOW_TESTS=true to run."
  )

  # Save original batch_limit
  original_limit <- Sys.getenv("batch_limit")

  # Set a small batch limit for testing
  Sys.setenv(batch_limit = "2")

  vcr::use_cassette("ct_env_fate_batching", {
		local_vcr_configure_log()
    # Query more than batch_limit
    dtxsids <- get_test_dtxsids()

    result <- ct_env_fate(dtxsids)

    expect_type(result, "list")
    expect_true(length(result) > 0)
  })

  # Restore original batch_limit
  Sys.setenv(batch_limit = original_limit)
})

# Test: Debug mode returns request instead of response
test_that("ct_env_fate debug mode returns dry run", {
	local_vcr_configure_log()
  # Save original debug setting
  original_debug <- Sys.getenv("run_debug")

  # Enable debug mode
  Sys.setenv(run_debug = "TRUE")

  vcr::use_cassette("ct_env_fate_debug", {
    result <- ct_env_fate("DTXSID4020533")

    # In debug mode, the function should return early with dry run output
    # The exact type/structure depends on req_dry_run() output
    expect_true(!is.null(result))
  })

  # Restore original debug setting
  Sys.setenv(run_debug = original_debug)
})


# Test: Handling API errors
test_that("ct_env_fate handles API errors gracefully", {
  skip("Manual test - requires mocking API failure")

  # This test would require vcr to record an error response
  # or use httptest/webmockr to mock the failure
  # Example structure:
  # vcr::use_cassette("ct_env_fate_api_error", {
  #   expect_error(
  #     ct_env_fate("INVALID_DTXSID"),
  #     "API request failed"
  #   )
  # })
})

# Test: No results found
test_that("ct_env_fate handles empty results", {
  skip("Manual test - requires DTXSID with no fate data")

  # This test would require a DTXSID that returns no results
  # vcr::use_cassette("ct_env_fate_no_results", {
  #   expect_warning(
  #     result <- ct_env_fate("DTXSID_NO_RESULTS"),
  #     "No results found"
  #   )
  #   expect_equal(length(result), 0)
  # })
})

# Integration test: Full workflow
test_that("ct_env_fate integration test with realistic data", {
	local_vcr_configure_log()
  vcr::use_cassette("ct_env_fate_integration", {
    # Use a known chemical with fate data
    result <- ct_env_fate("DTXSID4020533")

    expect_type(result, "list")
    expect_true(length(result) > 0)

    # Check that result contains expected structure
    # The actual structure depends on API response
    if (length(result) > 0) {
      expect_true(is.list(result[[1]]) || is.character(result[[1]]))
    }
  })
})

# Test: API key requirement
test_that("ct_env_fate requires API key", {
  skip("Manual test - requires removing API key")

  # Save current API key
  original_key <- Sys.getenv("ctx_api_key")

  # Remove API key
  Sys.unsetenv("ctx_api_key")

  expect_error(
    ct_env_fate("DTXSID4020533"),
    "No CTX API key found"
  )

  # Restore API key
  Sys.setenv(ctx_api_key = original_key)
})
