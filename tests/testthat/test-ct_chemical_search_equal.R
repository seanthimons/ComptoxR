# Tests for ct_chemical_search_equal functions

test_that("ct_chemical_search_equal_bulk returns results for valid queries", {
  vcr::use_cassette("ct_chemical_search_equal_bulk", {
    result <- ct_chemical_search_equal_bulk(c("DTXSID7020182", "DTXSID9020112"))
    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) > 0)
  })
})

test_that("ct_chemical_search_equal_bulk handles single query", {
  vcr::use_cassette("ct_chemical_search_equal_bulk_single", {
    result <- ct_chemical_search_equal_bulk("DTXSID7020182")
    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) > 0)
  })
})

test_that("ct_chemical_search_equal_bulk validates input", {
  expect_error(
    ct_chemical_search_equal_bulk(c()),
    "Query must contain at least one non-empty value"
  )
  expect_error(
    ct_chemical_search_equal_bulk(NA),
    "Query must contain at least one non-empty value"
  )
})
