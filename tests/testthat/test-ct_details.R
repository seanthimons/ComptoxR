# Tests for ct_details
# Generated using metadata-based test generator

test_that("ct_details works with single input", {
  vcr::use_cassette("ct_details_single", {
    result <- ct_details(query = "DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_details handles batch requests", {
  vcr::use_cassette("ct_details_batch", {
    result <- ct_details(query = c("DTXSID7020182", "DTXSID3060245"))
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_details handles errors gracefully", {
  expect_error(ct_details())
})
