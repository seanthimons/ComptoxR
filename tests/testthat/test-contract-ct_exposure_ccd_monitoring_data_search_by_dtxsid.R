# Generated with specmill; do not edit by hand.
testthat::test_that("ct_exposure_ccd_monitoring_data_search_by_dtxsid completes the fixed call sequence", {
  fixtures <- readRDS(testthat::test_path("fixtures/specmill-contracts.rds"))
  contract <- fixtures[["ct_exposure_ccd_monitoring_data_search_by_dtxsid"]]
  if (is.null(contract)) {
    contract <- fixtures[["GET /exposure/ccd/monitoring-data/search/by-dtxsid/{dtxsid}"]]
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
  result <- do.call(ComptoxR::ct_exposure_ccd_monitoring_data_search_by_dtxsid, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
