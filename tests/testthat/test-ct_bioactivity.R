# Tests for ct_bioactivity (updated for Phase 28 migration)
# ct_bioactivity() wrapper removed - now test individual endpoint stubs

test_that("ct_bioactivity_data_search_bulk works with single DTXSID", {
  vcr::use_cassette("ct_bioactivity_single", {
    result <- ct_bioactivity_data_search_bulk(query = "DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_bioactivity_data_search_bulk handles batch requests", {
  vcr::use_cassette("ct_bioactivity_batch", {
    result <- ct_bioactivity_data_search_bulk(query = c("DTXSID7020182", "DTXSID3060245"))
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_bioactivity_data_search_bulk handles annotate parameter", {
  vcr::use_cassette("ct_bioactivity_annotate", {
    result <- ct_bioactivity_data_search_bulk(query = "DTXSID7020182", annotate = TRUE)
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_bioactivity_data_search_bulk handles errors gracefully", {
  expect_error(ct_bioactivity_data_search_bulk())
})
