# Generated with specmill; do not edit by hand.
testthat::test_that("ct_hazard_toxref_observations_search_by_study_id completes the fixed call sequence", {
  fixtures <- readRDS(testthat::test_path("fixtures/specmill-contracts.rds"))
  contract <- fixtures[["ct_hazard_toxref_observations_search_by_study_id"]]
  if (is.null(contract)) {
    contract <- fixtures[["GET /hazard/toxref/observations/search/by-study-id/{studyId}"]]
  }
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
  testthat::local_mocked_bindings(.ct_request = mock_for(".ct_request"), .package = "ComptoxR")
  result <- do.call(ComptoxR::ct_hazard_toxref_observations_search_by_study_id, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
