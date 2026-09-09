# Intentional offline contract for a manual wrapper outside schema coverage.
test_that("pubchem_search completes its manual helper contract", {
  expected <- list(
    query = "aspirin",
    namespace = "name",
    operation = "cids",
    pluck_path = c("IdentifierList", "CID"),
    tidy = FALSE
  )
  response <- list(2244L)
  captured <- list()
  local_mocked_bindings(
    generic_pubchem_request = function(...) {
      captured[[length(captured) + 1L]] <<- list(...)
      response
    },
    .package = "ComptoxR"
  )
  result <- do.call(ComptoxR::pubchem_search, list(query = "aspirin", cache = FALSE))
  expect_identical(captured, list(expected))
  expect_identical(result, tibble::tibble(cid = 2244L))
})
