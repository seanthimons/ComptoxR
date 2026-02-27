# Tests for ct_bioactivity
# Generated using metadata-based test generator

test_that("ct_bioactivity works with single input", {
  vcr::use_cassette("ct_bioactivity_single", {
    result <- ct_bioactivity(search_type = "equals")
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_bioactivity handles batch requests", {
  vcr::use_cassette("ct_bioactivity_batch", {
    result <- ct_bioactivity(search_type = c("equals", "equals"))
    expect_s3_class(result, "tbl_df")
  })
})
test_that("ct_bioactivity handles errors gracefully", {
  expect_error(ct_bioactivity())
})
