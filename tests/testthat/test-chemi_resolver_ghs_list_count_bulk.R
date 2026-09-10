# Generated with specmill; do not edit by hand.
testthat::test_that("chemi_resolver_ghs_list_count_bulk completes the fixed request contract", {
  captured <- NULL
  calls <- 0L
  mock <- function(...) {
    calls <<- calls + 1L
    captured <<- list(...)
    list(list(hcode = "H301", count = 2L))
  }
  testthat::local_mocked_bindings(generic_chemi_request = mock, .package = "ComptoxR")
  result <- ComptoxR::chemi_resolver_ghs_list_count_bulk()
  testthat::expect_identical(
    captured,
    list(endpoint = "resolver/ghs-list-count", body = structure(list(), names = character(0)), tidy = FALSE)
  )
  testthat::expect_identical(calls, 1L)
  testthat::expect_identical(result, list(list(hcode = "H301", count = 2L)))
})
