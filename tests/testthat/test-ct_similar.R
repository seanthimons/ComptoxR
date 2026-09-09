# Intentional offline contract for a manual wrapper outside schema coverage.
test_that("ct_similar completes its manual helper contract", {
  expected <- list(
    query = "DTXSID7020182",
    endpoint = "similar-compound/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    server = "https://comptox.epa.gov/dashboard-api/",
    0.8
  )
  response <- tibble::tibble(dtxsid = "DTXSID0024842", similarity = 0.9)
  captured <- list()
  local_mocked_bindings(
    generic_request = function(...) {
      captured[[length(captured) + 1L]] <<- list(...)
      response
    },
    .package = "ComptoxR"
  )
  result <- do.call(ComptoxR::ct_similar, list(query = "DTXSID7020182"))
  expect_identical(captured, list(expected))
  expect_identical(result, tibble::tibble(dtxsid = "DTXSID0024842", similarity = 0.9))
})
