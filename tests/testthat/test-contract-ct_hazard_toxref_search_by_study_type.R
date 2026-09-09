# Generated with apipak; do not edit by hand.
testthat::test_that("ct_hazard_toxref_search_by_study_type completes the fixed call sequence", {
  contract <- readRDS(testthat::test_path("fixtures/apipak/ctx.rds"))[["ct_hazard_toxref_search_by_study_type"]]
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
  testthat::local_mocked_bindings(generic_request = mock_for("generic_request"), .package = "ComptoxR")
  result <- do.call(ComptoxR::ct_hazard_toxref_search_by_study_type, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
