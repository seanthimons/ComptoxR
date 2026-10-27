# Generated with specmill; do not edit by hand.
testthat::test_that("chemi_services_cim_component_info completes the fixed call sequence", {
  fixtures <- readRDS(testthat::test_path("fixtures/specmill-contracts.rds"))
  contract <- fixtures[["chemi_services_cim_component_info"]]
  if (is.null(contract)) {
    contract <- fixtures[["GET /api/services/cim_component_info"]]
  }
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
  result <- do.call(ComptoxR::chemi_services_cim_component_info, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
