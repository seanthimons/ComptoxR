# Generated with specmill; do not edit by hand.
testthat::test_that("epi_ecosar_polymer_polycationic completes the fixed call sequence", {
  fixtures <- readRDS(testthat::test_path("fixtures/specmill-full-contracts.rds"))
  contract <- fixtures[["epi_ecosar_polymer_polycationic"]]
  if (is.null(contract)) {
    contract <- fixtures[["GET /api/ecosar/polymer/polycationic"]]
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
  result <- do.call(ComptoxR::epi_ecosar_polymer_polycationic, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
