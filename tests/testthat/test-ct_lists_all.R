# Tests for ct_lists_all
# Generated using metadata-based test generator

test_that("ct_lists_all works with single input", {
  vcr::use_cassette("ct_lists_all_single", {
    result <- ct_lists_all(return_dtxsid = FALSE)
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_lists_all handles batch requests", {
  vcr::use_cassette("ct_lists_all_batch", {
    result <- ct_lists_all(return_dtxsid = c(FALSE, FALSE))
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_lists_all handles errors gracefully", {
  expect_error(ct_lists_all())
})
