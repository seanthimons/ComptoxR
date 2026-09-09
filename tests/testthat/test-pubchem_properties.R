# Intentional offline contract for a manual wrapper outside schema coverage.
test_that("pubchem_properties completes its manual helper contract", {
  expected <- list(
    namespace = "cid",
    operation = "property/MolecularFormula",
    method = "POST",
    body = list(cid = "2244,6623"),
    pluck_path = c("PropertyTable", "Properties"),
    tidy = TRUE
  )
  response <- tibble::tibble(CID = c(2244L, 6623L), MolecularFormula = c("C9H8O4", "C8H10N4O2"))
  captured <- list()
  local_mocked_bindings(
    generic_pubchem_request = function(...) {
      captured[[length(captured) + 1L]] <<- list(...)
      response
    },
    .package = "ComptoxR"
  )
  result <- do.call(
    ComptoxR::pubchem_properties,
    list(cid = c(2244L, 6623L), properties = "MolecularFormula", cache = FALSE)
  )
  expect_identical(captured, list(expected))
  expect_identical(result, tibble::tibble(CID = c(2244L, 6623L), MolecularFormula = c("C9H8O4", "C8H10N4O2")))
})
