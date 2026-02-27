# Tests for ct_descriptors
# Generated using metadata-based test generator

test_that("ct_descriptors works with single input", {
  vcr::use_cassette("ct_descriptors_single", {
    result <- ct_descriptors(query = "DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_descriptors handles batch requests", {
  vcr::use_cassette("ct_descriptors_batch", {
    result <- ct_descriptors(query = c("DTXSID7020182", "DTXSID3060245"))
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_descriptors handles errors gracefully", {
  expect_error(ct_descriptors())
})
