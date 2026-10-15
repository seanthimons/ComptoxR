test_that("resolver queries fail validation before requesting", {
  calls <- 0L
  testthat::local_mocked_bindings(
    generic_request = function(...) {
      calls <<- calls + 1L
      stop("unexpected request")
    },
    .package = "ComptoxR"
  )
  for (fun in list(chemi_resolver_lookup, chemi_resolver_lookupCASRN)) {
    expect_error(fun(), "query")
    for (query in list(NULL, character(), "", NA_character_, c("one", "two"))) {
      expect_error(fun(query), "query")
    }
  }
  expect_identical(calls, 0L)
})
