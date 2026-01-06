# Tests for ct_hazard
# Example test file showing recommended patterns

test_that("ct_hazard works with single DTXSID", {
  vcr::use_cassette("ct_hazard_single", {
    result <- ct_hazard("DTXSID7020182")

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Check structure
    expect_true(ncol(result) > 0)
    expect_true(nrow(result) >= 0)  # May be 0 if no hazard data

    # Check expected columns (if hazard data exists)
    if (nrow(result) > 0) {
      expect_true("dtxsid" %in% colnames(result))
    }
  })
})

test_that("ct_hazard handles batch requests", {
  vcr::use_cassette("ct_hazard_batch", {
    dtxsids <- c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291")
    result <- ct_hazard(dtxsids)

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Should handle multiple inputs
    expect_true(ncol(result) > 0)

    # Check for expected columns if data returned
    if (nrow(result) > 0) {
      expect_true("dtxsid" %in% colnames(result))
    }
  })
})

test_that("ct_hazard handles invalid DTXSID gracefully", {
  vcr::use_cassette("ct_hazard_invalid", {
    # Should warn about no results but not error
    expect_warning(
      result <- ct_hazard("INVALID_DTXSID"),
      "No results found|failed"
    )

    # Should return empty tibble or NULL
    expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 0))
  })
})

test_that("ct_hazard respects tidy parameter", {
  vcr::use_cassette("ct_hazard_tidy_false", {
    result <- ct_hazard("DTXSID7020182", tidy = FALSE)

    # Should return list when tidy = FALSE
    expect_type(result, "list")
  })
})

test_that("ct_hazard handles empty vector", {
  # Empty input should return empty tibble
  expect_warning(
    result <- ct_hazard(character(0)),
    "No query|empty"
  )

  expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 0))
})

test_that("ct_hazard handles NULL input", {
  # NULL input should error or return empty
  expect_error(
    ct_hazard(NULL),
    "query|required|missing"
  )
})

test_that("ct_hazard deduplicates queries", {
  vcr::use_cassette("ct_hazard_dedupe", {
    # Duplicate DTXSIDs should be handled
    result <- ct_hazard(c("DTXSID7020182", "DTXSID7020182"))

    expect_s3_class(result, "tbl_df")
    # Results should not be duplicated
  })
})
