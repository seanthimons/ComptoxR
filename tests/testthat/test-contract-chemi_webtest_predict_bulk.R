# Generated with specmill; do not edit by hand.
testthat::test_that("chemi_webtest_predict_bulk completes the fixed call sequence", {
  contract <- readRDS(testthat::test_path("fixtures/specmill/chemi-webtest.rds"))[["chemi_webtest_predict_bulk"]]
  withr::local_envvar(unlist(contract$environment, use.names = TRUE))
  captured <- list()
  mock_for <- function(name) {
    force(name)
    function(...) {
      position <- length(captured) + 1L
      captured[[position]] <<- list(helper = name, arguments = list(...))
      if (position > length(contract$calls)) {
        stop("Unexpected extra helper call")
      }
      contract$calls[[position]]$response
    }
  }
  testthat::local_mocked_bindings(
    chemi_resolver_lookup_bulk = mock_for("chemi_resolver_lookup_bulk"),
    generic_chemi_request = mock_for("generic_chemi_request"),
    .package = "ComptoxR"
  )
  result <- do.call(ComptoxR::chemi_webtest_predict_bulk, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
