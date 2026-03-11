# Tests for ct_functional_use (updated for Phase 28 migration)
# ct_functional_use() wrapper removed - now test ct_exposure_functional_use_search_bulk()

test_that("ct_exposure_functional_use_search_bulk works with single input", {
  vcr::use_cassette("ct_functional_use_single", {
    result <- ct_exposure_functional_use_search_bulk(query = "DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_exposure_functional_use_search_bulk handles batch requests", {
  vcr::use_cassette("ct_functional_use_batch", {
    result <- ct_exposure_functional_use_search_bulk(query = c("DTXSID7020182", "DTXSID3060245"))
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_exposure_functional_use_search_bulk handles errors gracefully", {
  expect_error(ct_exposure_functional_use_search_bulk())
})
