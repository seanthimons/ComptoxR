# Tests for ct_functional_use
# Generated using metadata-based test generator

test_that("ct_functional_use works with single input", {
  vcr::use_cassette("ct_functional_use_single", {
    result <- ct_functional_use(query = "DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_functional_use handles batch requests", {
  vcr::use_cassette("ct_functional_use_batch", {
    result <- ct_functional_use(query = c("DTXSID7020182", "DTXSID3060245"))
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_functional_use handles errors gracefully", {
  expect_error(ct_functional_use())
})
