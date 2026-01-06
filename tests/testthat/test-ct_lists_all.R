# Tests for ct_lists_all
# Custom test - no query parameter required

test_that("ct_lists_all retrieves all public lists", {
  vcr::use_cassette("ct_lists_all_basic", {
    result <- ct_lists_all()

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Should return multiple lists
    expect_true(nrow(result) > 0)
    expect_true(ncol(result) > 0)

    # Check for expected columns
    expect_true("listName" %in% colnames(result))
  })
})

test_that("ct_lists_all returns DTXSIDs when requested", {
  vcr::use_cassette("ct_lists_all_with_dtxsids", {
    result <- ct_lists_all(return_dtxsid = TRUE)

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Should have dtxsids column
    expect_true("dtxsids" %in% colnames(result))

    # DTXSIDs should be comma-separated strings
    if (nrow(result) > 0) {
      expect_type(result$dtxsids, "character")
    }
  })
})

test_that("ct_lists_all coerces DTXSIDs to vectors", {
  vcr::use_cassette("ct_lists_all_coerced", {
    result <- ct_lists_all(return_dtxsid = TRUE, coerce = TRUE)

    # When coerced, returns a list of lists
    expect_type(result, "list")

    # Each element should have dtxsids as a vector
    if (length(result) > 0) {
      first_list <- result[[1]]
      expect_type(first_list$dtxsids, "character")
      expect_true(length(first_list$dtxsids) >= 1)
    }
  })
})

test_that("ct_lists_all warns when coerce=TRUE but return_dtxsid=FALSE", {
  vcr::use_cassette("ct_lists_all_coerce_warning", {
    expect_warning(
      result <- ct_lists_all(return_dtxsid = FALSE, coerce = TRUE),
      "need to request DTXSIDs"
    )

    # Should still return tibble
    expect_s3_class(result, "tbl_df")
  })
})
