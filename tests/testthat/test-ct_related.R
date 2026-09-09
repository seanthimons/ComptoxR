# Intentional offline contract for a manual wrapper outside schema coverage.
test_that("ct_related completes its manual helper contract", {
  expected <- list(
    query = NULL,
    endpoint = "related-substances/search/by-dtxsid",
    method = "GET",
    batch_limit = 0,
    server = "https://comptox.epa.gov/dashboard-api/ccdapp2/",
    auth = FALSE,
    tidy = FALSE,
    id = "DTXSID7020182"
  )
  response <- list(
    data = list(
      list(dtxsid = "DTXSID7020182", relationship = "self"),
      list(dtxsid = "DTXSID0024842", relationship = "parent")
    )
  )
  captured <- list()
  local_mocked_bindings(
    generic_request = function(...) {
      captured[[length(captured) + 1L]] <<- list(...)
      response
    },
    .package = "ComptoxR"
  )
  result <- do.call(ComptoxR::ct_related, list(query = "DTXSID7020182"))
  expect_identical(captured, list(expected))
  expect_identical(result, tibble::tibble(query = "DTXSID7020182", child = "DTXSID0024842", relationship = "parent"))
})
