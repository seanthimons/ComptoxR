test_that("native classifier bodies follow the service request schema", {
  captured <- NULL
  testthat::local_mocked_bindings(.ct_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, chemi_resolver_lookup_bulk = function(...) stop("unexpected resolver call"),
  .package = "ComptoxR")
  names <- c("chemi_amnb_nate_bulk", "chemi_arn_cats_bulk", "chemi_ncc_cats_bulk",
    "chemi_pfas_atlas_bulk", "chemi_pfas_cats_bulk")
  records <- list(list(id = "one", smiles = "CCO"), list(id = "CCN", smiles = "CCN"))
  for (name in names) {
    fun <- getExportedValue("ComptoxR", name)
    expect_identical(fun(chemicals = c(one = "CCO", "CCN", "", NA_character_, "CCN", one = "CCO")),
      list(result = "unchanged"))
    expect_identical(captured$body$chemicals, records)
    expect_identical(setdiff(names(captured$body), "chemicals"),
      if (name == "chemi_arn_cats_bulk") "model" else character())
    for (empty in list(NULL, character(), c("", NA_character_))) {
      captured <- NULL
      expect_error(fun(chemicals = empty), "Supply chemicals or smiles.", fixed = TRUE)
      expect_null(captured)
    }
  }
  chemi_arn_cats_bulk(smiles = "CCO", model = NULL)
  expect_identical(captured$body, list(smiles = list("CCO")))
  chemi_arn_cats_bulk(smiles = c(a = "CCO", "CCN", b = "CCO"))
  expect_identical(captured$body, list(model = "RF", smiles = list("CCO", "CCN")))
  frame <- data.frame(id = 1:2, smiles = c("CCO", "CCN"))
  chemi_ncc_cats_bulk(chemicals = frame)
  expect_identical(captured$body, list(chemicals = frame))
})

test_that("native classifiers resolve identifiers to SMILES before the request", {
  captured <- NULL
  looked_up <- NULL
  testthat::local_mocked_bindings(.ct_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, chemi_resolver_lookup_bulk = function(ids, ...) {
    looked_up <<- ids
    lapply(ids, function(id) {
      if (id == "DTXSID7020182") {
        list(result = "FOUND", query = id, chemical = list(canonicalSmiles = "CC(C)(c1ccc(O)cc1)c1ccc(O)cc1"))
      } else {
        list(result = "NOT_RESOLVED", query = id)
      }
    })
  }, .package = "ComptoxR")
  for (name in c("chemi_amnb_nate_bulk", "chemi_arn_cats_bulk", "chemi_ncc_cats_bulk",
    "chemi_pfas_atlas_bulk", "chemi_pfas_cats_bulk")) {
    fun <- getExportedValue("ComptoxR", name)
    expect_warning(
      fun(chemicals = c("DTXSID7020182", "CCO", bpa = "DTXSID7020182", "DTXSID7020182", "50-00-0")),
      "50-00-0"
    )
    expect_identical(looked_up, c("DTXSID7020182", "50-00-0"))
    expect_identical(captured$body$chemicals, list(
      list(id = "DTXSID7020182", smiles = "CC(C)(c1ccc(O)cc1)c1ccc(O)cc1"),
      list(id = "CCO", smiles = "CCO"),
      list(id = "bpa", smiles = "CC(C)(c1ccc(O)cc1)c1ccc(O)cc1")
    ))
  }
  chemi_pfas_cats_bulk(smiles = "DTXSID7020182")
  expect_identical(captured$body, list(smiles = list("CC(C)(c1ccc(O)cc1)c1ccc(O)cc1")))
  captured <- NULL
  expect_error(expect_warning(chemi_amnb_nate_bulk("50-00-0")), "Supply chemicals or smiles.", fixed = TRUE)
  expect_null(captured)
})
