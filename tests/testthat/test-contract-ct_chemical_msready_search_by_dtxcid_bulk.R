# Generated with specmill; do not edit by hand.
testthat::test_that("ct_chemical_msready_search_by_dtxcid_bulk completes the fixed call sequence", {
  fixtures <- readRDS(testthat::test_path("fixtures/specmill-full-contracts.rds"))
  contract <- fixtures[["ct_chemical_msready_search_by_dtxcid_bulk"]]
  if (is.null(contract)) {
    contract <- fixtures[["POST /chemical/msready/search/by-dtxcid/"]]
  }
  withr::local_envvar(unlist(contract$environment, use.names = TRUE))
  names(contract$inputs)[names(contract$inputs) == "body"] <- "dtxcid"
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
  result <- do.call(ComptoxR::ct_chemical_msready_search_by_dtxcid_bulk, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
