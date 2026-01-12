# Tests for chemi_toxprint
# Example test file for cheminformatics functions

test_that("chemi_toxprint works with single DTXSID", {
  vcr::use_cassette("chemi_toxprint_single", {
    result <- chemi_toxprint("DTXSID7020182")

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Check structure
    expect_true(ncol(result) > 0)
    expect_true(nrow(result) > 0)

    # Check for expected columns
    expect_true(any(grepl("dtxsid|sid|toxprint", colnames(result), ignore.case = TRUE)))
  })
})

test_that("chemi_toxprint handles batch requests", {
  vcr::use_cassette("chemi_toxprint_batch", {
    dtxsids <- c("DTXSID7020182", "DTXSID5032381")
    result <- chemi_toxprint(dtxsids)

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Should return results for multiple inputs
    expect_true(nrow(result) >= 2)
  })
})

test_that("chemi_toxprint handles options parameter", {
  vcr::use_cassette("chemi_toxprint_options", {
    result <- chemi_toxprint(
      "DTXSID7020182",
      options = list(standardize = TRUE)
    )

    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) > 0)
  })
})

test_that("chemi_toxprint respects tidy parameter", {
  vcr::use_cassette("chemi_toxprint_tidy_false", {
    result <- chemi_toxprint("DTXSID7020182", tidy = FALSE)

    # Should return list when tidy = FALSE
    expect_type(result, "list")
    expect_true(length(result) > 0)
  })
})

test_that("chemi_toxprint handles invalid DTXSID gracefully", {
  vcr::use_cassette("chemi_toxprint_invalid", {
    # Should handle errors gracefully
    expect_warning(
      result <- chemi_toxprint("INVALID_DTXSID"),
      "failed|error|No results"
    )

    # Should return empty result
    expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 0))
  })
})
