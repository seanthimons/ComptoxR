# Tests for ct_list (updated for Phase 28 migration)
# ct_list() wrapper removed - now test generated stub with hook parameters
# The generated stub uses ct_chemical_list_search_by_name() with hooks

test_that("ct_chemical_list_search_by_name works with single input", {
  vcr::use_cassette("ct_list_single", {
    result <- ct_chemical_list_search_by_name(list_name = "PRODWATER")
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_chemical_list_search_by_name works with documented example", {
  vcr::use_cassette("ct_list_example", {
    result <- ct_chemical_list_search_by_name(list_name = "PRODWATER")
    expect_true(!is.null(result))
  })
})

test_that("ct_chemical_list_search_by_name handles batch requests", {
  vcr::use_cassette("ct_list_batch", {
    result <- ct_chemical_list_search_by_name_bulk(query = c("PRODWATER", "CWA311HS"))
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_chemical_list_search_by_name handles invalid input gracefully", {
  vcr::use_cassette("ct_list_error", {
    result <- suppressWarnings(ct_chemical_list_search_by_name(list_name = "NONEXISTENT_LIST_XYZ"))
    expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 0))
  })
})
