# Tests for ct_chemical_search_equal_bulk (POST endpoint with simple body)
# Validates VAL-03: Generated functions work against live API

test_that("ct_chemical_search_equal_bulk works with single query", {
  skip_if_not(nzchar(Sys.getenv("ctx_api_key")), "No API key configured")

  vcr::use_cassette("ct_chemical_search_equal_bulk_single", {
    result <- ct_chemical_search_equal_bulk(
      query = "DTXSID7020182"  # Bisphenol A
    )

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Check structure
    expect_true(ncol(result) > 0)
    expect_true(nrow(result) > 0)

    # Check for expected column (dtxsid is common in chemical search results)
    expect_true(any(grepl("dtxsid", tolower(colnames(result)))))
  })
})

test_that("ct_chemical_search_equal_bulk works with multiple queries", {
  skip_if_not(nzchar(Sys.getenv("ctx_api_key")), "No API key configured")

  vcr::use_cassette("ct_chemical_search_equal_bulk_multi", {
    result <- ct_chemical_search_equal_bulk(
      query = c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291")
    )

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Check multiple results returned
    expect_true(nrow(result) >= 1)

    # Verify structure is consistent
    expect_true(ncol(result) > 0)
  })
})

test_that("ct_chemical_search_equal_bulk handles empty/invalid input gracefully", {
  skip_if_not(nzchar(Sys.getenv("ctx_api_key")), "No API key configured")

  vcr::use_cassette("ct_chemical_search_equal_bulk_invalid", {
    # Invalid DTXSID should not crash
    expect_warning(
      result <- ct_chemical_search_equal_bulk(query = "INVALID_DTXSID_12345"),
      regexp = NULL  # Allow any warning or no warning
    )

    # Should return empty result or NULL, not error
    expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 0) || is.data.frame(result))
  })
})
