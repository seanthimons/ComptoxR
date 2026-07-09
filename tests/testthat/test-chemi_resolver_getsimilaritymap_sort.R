if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

test_that("chemi_resolver_getsimilaritymap forwards sort as a query parameter", {
  captured <- NULL
  testthat::local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(list(
        result = "FOUND",
        chemical = list(
          chemId = "DTXSID1",
          canonicalSmiles = "C",
          casrn = "50-00-0",
          inchi = "InChI=1S/CH2O",
          inchiKey = "WSFSSNUMVMOOMR-UHFFFAOYSA-N",
          name = "formaldehyde"
        )
      ))
    },
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list()
    },
    .package = "ComptoxR"
  )

  ComptoxR::chemi_resolver_getsimilaritymap(query = "DTXSID1", sort = FALSE)

  expect_equal(captured$endpoint, "resolver/getsimilaritymap")
  expect_equal(captured$sort, "false")
  expect_false(captured$tidy)
})
