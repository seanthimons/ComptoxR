# Generated with specmill; do not edit by hand.
testthat::test_that("chemi_chet_chemicals_maps completes the fixed call sequence", {
  fixtures <- readRDS(testthat::test_path("fixtures/specmill-rebuild-contracts.rds"))
  contract <- fixtures[["chemi_chet_chemicals_maps"]]
  if (is.null(contract)) {
    contract <- fixtures[["GET /chemicals/maps"]]
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
  result <- do.call(ComptoxR::chemi_chet_chemicals_maps, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
