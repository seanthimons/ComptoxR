if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

resolver_similarity_map_payload <- function() {
  list(
    order = list(
      list(chemical = list(sid = "DTXSID-A", name = "A")),
      list(chemical = list(sid = "DTXSID-B", name = "B"))
    ),
    similarity = list(
      list(list(sim = 0), list(sim = 0.25)),
      list(list(sim = 0.25), list(sim = 0))
    )
  )
}

test_that("chemi_resolver_getsimilaritymap sends flat Chemical records", {
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
      resolver_similarity_map_payload()
    },
    .package = "ComptoxR"
  )

  result <- ComptoxR::chemi_resolver_getsimilaritymap(
    query = "DTXSID1",
    section = "PubChem",
    hclust_method = "single"
  )

  expect_equal(captured$endpoint, "resolver/getsimilaritymap")
  expect_equal(captured$sort, "false")
  expect_false(captured$tidy)
  expect_equal(captured$options$section, "PubChem")
  expect_equal(captured$chemicals[[1]]$sid, "DTXSID1")
  expect_null(captured$chemicals[[1]]$chemical)
  expect_true(is.matrix(result$similarity))
  expect_identical(rownames(result$similarity), c("DTXSID-A", "DTXSID-B"))
  expect_identical(colnames(result$similarity), c("DTXSID-A", "DTXSID-B"))
  expect_identical(result$hc$method, "single")
})
