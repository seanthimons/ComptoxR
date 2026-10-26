# Generated with specmill; do not edit by hand.
testthat::test_that("chemi_amos_get_ir_spectrum completes the fixed call sequence", {
  fixtures <- readRDS(testthat::test_path("fixtures/specmill-pilot-contracts.rds"))
  contract <- fixtures[["chemi_amos_get_ir_spectrum"]]
  if (is.null(contract)) {
    contract <- fixtures[["GET /api/amos/get_ir_spectrum/{internal_id}"]]
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
  result <- do.call(ComptoxR::chemi_amos_get_ir_spectrum, contract$inputs)
  testthat::expect_identical(captured, lapply(contract$calls, function(x) x[c('helper', 'arguments')]))
  testthat::expect_identical(result, contract$result)
})
