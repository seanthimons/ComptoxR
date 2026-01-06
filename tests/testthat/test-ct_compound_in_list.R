# Tests for ct_compound_in_list
# Custom test - returns named list, not tibble

test_that("ct_compound_in_list finds lists for valid DTXSID", {
  vcr::use_cassette("ct_compound_in_list_single", {
    result <- ct_compound_in_list("DTXSID7020182")

    # Check return type - should be a list
    expect_type(result, "list")

    # Should have names matching query
    expect_true("DTXSID7020182" %in% names(result))

    # Result should contain list names
    if (length(result) > 0) {
      lists <- result[[1]]
      expect_type(lists, "character")
      expect_true(length(lists) > 0)
    }
  })
})

test_that("ct_compound_in_list handles batch queries", {
  vcr::use_cassette("ct_compound_in_list_batch", {
    dtxsids <- c("DTXSID7020182", "DTXSID5032381")
    result <- ct_compound_in_list(dtxsids)

    # Check return type
    expect_type(result, "list")

    # Should have names for each query
    expect_true(all(dtxsids %in% names(result)))

    # Each result should be a character vector
    for (res in result) {
      expect_type(res, "character")
    }
  })
})

test_that("ct_compound_in_list handles DTXSID not in any list", {
  vcr::use_cassette("ct_compound_in_list_not_found", {
    # Use a DTXSID that might not be in any lists
    expect_warning(
      result <- ct_compound_in_list("DTXSID0000000001"),
      "No lists found|No results"
    )

    # Should return empty list or NULL
    expect_true(length(result) == 0 || is.null(result))
  })
})

test_that("ct_compound_in_list handles invalid DTXSID", {
  vcr::use_cassette("ct_compound_in_list_invalid", {
    expect_warning(
      result <- ct_compound_in_list("INVALID_DTXSID"),
      "No lists found|failed|No results"
    )

    # Should return empty list or NULL
    expect_true(length(result) == 0 || is.null(result))
  })
})
