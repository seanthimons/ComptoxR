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

test_that("native classifiers keep DUPLICATE and CONVERTED resolver results", {
  captured <- NULL
  smiles <- "CC(C)(c1ccc(O)cc1)c1ccc(O)cc1"
  testthat::local_mocked_bindings(.ct_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, chemi_resolver_lookup_bulk = function(ids, ...) {
    list(
      list(result = "FOUND", query = ids[[1]], chemical = list(canonicalSmiles = smiles)),
      list(result = "DUPLICATE", query = ids[[2]], chemical = list(canonicalSmiles = smiles)),
      list(result = "CONVERTED", query = ids[[3]], chemical = list(smiles = "CCO"))
    )
  }, .package = "ComptoxR")
  expect_no_warning(chemi_amnb_nate_bulk(c("DTXSID7020182", "80-05-7", "64-17-5")))
  expect_identical(captured$body$chemicals, list(
    list(id = "DTXSID7020182", smiles = smiles),
    list(id = "80-05-7", smiles = smiles),
    list(id = "64-17-5", smiles = "CCO")
  ))
  converted <- list(
    result = "CONVERTED",
    chemical = list(chemId = "LFQSCWFLJHTTHZ-UHFFFAOYSA-N", smiles = "CCO")
  )
  expect_identical(descriptor_resolved_sid(converted), NA_character_)
})

test_that("resolver items map to inputs when one input returns several items", {
  bpa <- "CC(C)(C1C=CC(O)=CC=1)C1C=CC(O)=CC=1"
  item <- function(query, result, smiles = NULL, sid = NULL) {
    chemical <- list(canonicalSmiles = smiles, sid = sid)
    list(result = result, query = query, chemical = chemical)
  }
  # Shape of a live response: an InChIKey with three matches and a CASRN echoed
  # without its leading zeros.
  live <- list(
    item("LFQSCWFLJHTTHZ-UHFFFAOYSA-N", "FOUND", "CCO", "DTXSID9020584"),
    item("LFQSCWFLJHTTHZ-UHFFFAOYSA-N", "DUPLICATE", sid = "DTXSID4028331"),
    item("LFQSCWFLJHTTHZ-UHFFFAOYSA-N", "DUPLICATE", sid = "DTXSID101057201"),
    item("DTXSID7020182", "FOUND", bpa, "DTXSID7020182"),
    item("80-05-7", "DUPLICATE", bpa, "DTXSID7020182"),
    item("50-00-0", "FOUND", "C=O", "DTXSID7020637"),
    list(result = "NOT_RESOLVED", query = "DTXSID0000000000")
  )
  lookup <- c(
    "LFQSCWFLJHTTHZ-UHFFFAOYSA-N", "DTXSID7020182", "0000080-05-7", "50-00-0",
    "DTXSID0000000000"
  )
  items <- descriptor_resolver_items(live, lookup)
  expect_identical(names(items), lookup)
  expect_identical(
    unname(vapply(items, descriptor_resolved_smiles, character(1))),
    c("CCO", bpa, bpa, "C=O", NA)
  )
  expect_identical(descriptor_resolved_sid(items[[1]]), "DTXSID9020584")

  # Two inputs that echo the same query: only exact echoes match.
  merged <- list(
    item("80-05-7", "FOUND", bpa),
    item("80-05-7", "DUPLICATE", bpa),
    item("50-00-0", "FOUND", "C=O")
  )
  items <- descriptor_resolver_items(
    merged, c("0000080-05-7", "80-05-7", "50-00-0")
  )
  expect_null(items[["0000080-05-7"]])
  expect_identical(items[["80-05-7"]]$result, "FOUND")
  expect_identical(items[["50-00-0"]]$chemical$canonicalSmiles, "C=O")

  captured <- NULL
  testthat::local_mocked_bindings(.ct_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, chemi_resolver_lookup_bulk = function(ids, ...) {
    c(list(item(ids[[1]], "FOUND", bpa), item(ids[[1]], "DUPLICATE", bpa)), live[5:7])
  }, .package = "ComptoxR")
  expect_warning(chemi_amnb_nate_bulk(lookup[-1]), "DTXSID0000000000")
  expect_identical(captured$body$chemicals, list(
    list(id = "DTXSID7020182", smiles = bpa),
    list(id = "0000080-05-7", smiles = bpa),
    list(id = "50-00-0", smiles = "C=O")
  ))
})
