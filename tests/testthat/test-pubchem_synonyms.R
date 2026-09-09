# Intentional offline contract for a manual wrapper outside schema coverage.
test_that("pubchem_synonyms completes its manual helper contract", {
  expected <- list(
    query = 2244L,
    namespace = "cid",
    operation = "synonyms",
    pluck_path = c("InformationList", "Information"),
    tidy = FALSE
  )
  response <- list(list(CID = 2244L, Synonym = c("aspirin", "acetylsalicylic acid")))
  captured <- list()
  local_mocked_bindings(
    generic_pubchem_request = function(...) {
      captured[[length(captured) + 1L]] <<- list(...)
      response
    },
    .package = "ComptoxR"
  )
  result <- do.call(ComptoxR::pubchem_synonyms, list(cid = 2244L, cache = FALSE))
  expect_identical(captured, list(expected))
  expect_identical(result, tibble::tibble(cid = c(2244L, 2244L), synonym = c("aspirin", "acetylsalicylic acid")))
})
