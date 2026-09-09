# Intentional offline contract for a manual wrapper outside schema coverage.
test_that("chemi_classyfire completes its manual helper contract", {
  expected <- list(
    query = "DTXSID7020182",
    endpoint = "amos/get_classification_for_dtxsid/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE
  )
  response <- tibble::tibble(
    query = "DTXSID7020182",
    kingdom = "Organic",
    superklass = "Superclass",
    klass = "Class",
    subklass = "Subclass"
  )
  captured <- list()
  local_mocked_bindings(
    generic_request = function(...) {
      captured[[length(captured) + 1L]] <<- list(...)
      response
    },
    .package = "ComptoxR"
  )
  result <- do.call(ComptoxR::chemi_classyfire, list(query = "DTXSID7020182"))
  expect_identical(captured, list(expected))
  expect_identical(
    result,
    tibble::tibble(
      dtxsid = "DTXSID7020182",
      kingdom = "Organic",
      superclass = "Superclass",
      class = "Class",
      subclass = "Subclass"
    )
  )
})
