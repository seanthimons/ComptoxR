# Tests for chemi_cluster
# Generated using metadata-based test generator

test_that("chemi_cluster works with single input", {
  vcr::use_cassette("chemi_cluster_single", {
    result <- chemi_cluster(chemicals = "DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})
test_that("chemi_cluster handles batch requests", {
  vcr::use_cassette("chemi_cluster_batch", {
    result <- chemi_cluster(chemicals = c("DTXSID7020182", "DTXSID3060245"))
    expect_s3_class(result, "tbl_df")
  })
})
test_that("chemi_cluster handles errors gracefully", {
  expect_error(chemi_cluster())
})
