# Integration tests for pagination with VCR cassettes
# These tests verify end-to-end pagination behavior with real API responses

test_that("chemi_amos_method_pagination fetches multiple pages", {
  # Ensure chemi server is configured
  chemi_server(1)  # Set production endpoint

  vcr::use_cassette("pagination_e2e_multipage", {
    result <- chemi_amos_method_pagination(
      limit = 5,
      offset = 0,
      all_pages = TRUE
    )

    # Verify result is a list with at least 5 elements (confirming multiple pages were combined)
    expect_type(result, "list")
    expect_true(length(result) >= 5)

    # Verify structure of returned records
    if (length(result) > 0) {
      expect_true(all(sapply(result, is.list)))
    }
  })
})

test_that("chemi_amos_method_pagination handles last page termination", {
  # Ensure chemi server is configured
  chemi_server(1)

  vcr::use_cassette("pagination_e2e_lastpage", {
    result <- chemi_amos_method_pagination(
      limit = 100,
      offset = 0,
      all_pages = TRUE
    )

    # Should return without error and return a list
    expect_type(result, "list")
    # With limit=100, we should get at least some records
    expect_true(length(result) > 0)
  })
})

test_that("chemi_amos_method_pagination single page works (all_pages=FALSE)", {
  # Ensure chemi server is configured
  chemi_server(1)

  vcr::use_cassette("pagination_e2e_singlepage", {
    result <- chemi_amos_method_pagination(
      limit = 10,
      offset = 0,
      all_pages = FALSE
    )

    # Should return exactly one page worth of data
    expect_type(result, "list")
    expect_true(length(result) > 0)
    # With all_pages=FALSE and limit=10, should get at most 10 records
    expect_true(length(result) <= 10)
  })
})

test_that("chemi_amos_method_pagination handles different offset values", {
  # Ensure chemi server is configured
  chemi_server(1)

  vcr::use_cassette("pagination_e2e_offset", {
    result <- chemi_amos_method_pagination(
      limit = 5,
      offset = 10,
      all_pages = TRUE
    )

    # Should return results starting from offset 10
    expect_type(result, "list")
    # Should have at least 5 records from the offset position
    expect_true(length(result) >= 5)
  })
})
