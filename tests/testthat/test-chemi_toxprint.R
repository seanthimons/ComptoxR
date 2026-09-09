# Intentional offline contract for a manual wrapper outside schema coverage.
test_that("chemi_toxprint completes its manual helper contract", {
  expected <- list(
    query = "DTXSID7020182",
    endpoint = "toxprints/calculate",
    options = list(OR = 3L, PV1 = 0.05, TP = 3)
  )
  response <- tibble::tibble(bit = "fixture", value = 1L)
  captured <- list()
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured[[length(captured) + 1L]] <<- list(...)
      response
    },
    .package = "ComptoxR"
  )
  result <- do.call(ComptoxR::chemi_toxprint, list(query = "DTXSID7020182"))
  expect_identical(captured, list(expected))
  expect_identical(result, tibble::tibble(bit = "fixture", value = 1L))
})
