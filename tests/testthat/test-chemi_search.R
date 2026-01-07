# Tests for chemi_search

test_that("chemi_search works with exact search", {
  vcr::use_cassette("chemi_search_exact", {
    result <- chemi_search(query = "DTXSID7020182", search_type = "exact")
    expect_s3_class(result, "tbl_df")
    expect_true(ncol(result) > 0)
  })
})

test_that("chemi_search works with similarity search", {
  vcr::use_cassette("chemi_search_similar", {
    result <- chemi_search(
      query = "DTXSID7020182",
      search_type = "similar",
      min_similarity = 0.9
    )
    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) >= 0)
    if (nrow(result) > 0 && "similarity" %in% colnames(result)) {
      expect_true("relationship" %in% colnames(result))
    }
  })
})

test_that("chemi_search validates search_type", {
  expect_error(
    chemi_search(query = "DTXSID7020182", search_type = "invalid"),
    "arg"
  )
})

test_that("chemi_search requires query for exact search", {
  expect_error(
    chemi_search(query = NULL, search_type = "exact"),
    "requires a query"
  )
})

test_that("chemi_search validates min_similarity range", {
  expect_error(
    chemi_search(query = "DTXSID7020182", search_type = "similar", min_similarity = 1.5),
    "between 0 and 1"
  )
})

test_that("chemi_search validates hazard_name", {
  expect_error(
    chemi_search(query = NULL, search_type = "hazard", hazard_name = "invalid_hazard"),
    "Invalid hazard_name"
  )
})

test_that("chemi_search works with mass search", {
  vcr::use_cassette("chemi_search_mass", {
    result <- chemi_search(
      query = NULL,
      search_type = "mass",
      mass_type = "mono",
      min_mass = 100,
      max_mass = 150,
      limit = 10
    )
    expect_s3_class(result, "tbl_df")
  })
})

test_that("chemi_search works with hazard search", {
  vcr::use_cassette("chemi_search_hazard", {
    result <- chemi_search(
      query = NULL,
      search_type = "hazard",
      hazard_name = "cancer",
      min_toxicity = "H",
      limit = 10
    )
    expect_s3_class(result, "tbl_df")
  })
})
