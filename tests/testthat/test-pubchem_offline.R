# Handwritten offline tests for PubChem wrappers.
#
# These cover branching, validation, and response-shaping behavior that the
# generated single-call contract tests (test-pubchem_*.R) cannot express:
#   - allowlist / empty-input abort paths
#   - single-CID GET branch vs bulk POST batch branch
#   - input-type routing (GET name vs POST structure)
#   - empty-result warning + integer cid coercion
#   - tidy=TRUE long-format reshaping
#
# All shared request helpers are mocked; no network, no API key.

# Capture-and-return mock factory for generic_pubchem_request.
# `response` is returned from every mocked call.
pubchem_mock <- function(calls_env, response) {
  function(...) {
    captured <- list(...)
    calls_env$calls[[length(calls_env$calls) + 1L]] <- captured
    response
  }
}

# ---- pubchem_properties: validation / error paths ----

test_that("pubchem_properties aborts on invalid (path-injection) property name", {
  generated_contract_ensure_package()
  expect_error(
    ComptoxR::pubchem_properties(2244L, properties = c("XLogP", "../etc/passwd")),
    "Invalid PubChem property"
  )
})

test_that("pubchem_properties aborts when no valid integer CID remains", {
  generated_contract_ensure_package()
  expect_error(
    ComptoxR::pubchem_properties(NA_integer_, cache = FALSE),
    "at least one valid integer CID"
  )
  expect_error(
    suppressWarnings(ComptoxR::pubchem_properties(c("foo", "bar"), cache = FALSE)),
    "at least one valid integer CID"
  )
})

# ---- pubchem_properties: single-CID GET branch vs >1-CID POST batch branch ----

test_that("pubchem_properties single CID uses GET (query, no method/body)", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()
  resp <- tibble::tibble(CID = 2244L, MolecularWeight = 180.16, XLogP = 1.2)

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, resp),
    .package = "ComptoxR"
  )

  ComptoxR::pubchem_properties(2244L, properties = c("XLogP", "MolecularWeight"), cache = FALSE)

  expect_length(env$calls, 1L)
  call <- env$calls[[1L]]
  expect_equal(call[["query"]], 2244L)
  expect_null(call[["method"]]) # default GET
  expect_false("body" %in% names(call))
  # properties are sorted into the operation path
  expect_equal(call[["operation"]], "property/MolecularWeight,XLogP")
})

test_that("pubchem_properties >100 CIDs splits into batches of 100 POSTs", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()
  resp <- tibble::tibble(CID = integer(0))

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, resp),
    .package = "ComptoxR"
  )

  ComptoxR::pubchem_properties(1:150, properties = "XLogP", cache = FALSE)

  expect_length(env$calls, 2L)
  batch_sizes <- vapply(
    env$calls,
    function(call) {
      expect_equal(call[["method"]], "POST")
      length(strsplit(call[["body"]]$cid, ",", fixed = TRUE)[[1]])
    },
    integer(1)
  )
  expect_equal(sort(batch_sizes), c(50L, 100L))
})

# ---- pubchem_search: input-type routing, empty shaping, coercion, validation ----

test_that("pubchem_search name uses GET with query and coerces cid to integer", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, list(2244, 6623)),
    .package = "ComptoxR"
  )

  out <- ComptoxR::pubchem_search("aspirin", cache = FALSE)

  expect_length(env$calls, 1L)
  call <- env$calls[[1L]]
  expect_equal(call[["query"]], "aspirin")
  expect_equal(call[["namespace"]], "name")
  expect_null(call[["method"]]) # default GET, not POST
  expect_false("body" %in% names(call))

  expect_s3_class(out, "tbl_df")
  expect_type(out$cid, "integer")
  expect_equal(out$cid, c(2244L, 6623L))
})

test_that("pubchem_search smiles uses POST with structure body", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, list(2244)),
    .package = "ComptoxR"
  )

  ComptoxR::pubchem_search("CC(=O)O", type = "smiles", cache = FALSE)

  call <- env$calls[[1L]]
  expect_equal(call[["method"]], "POST")
  expect_equal(call[["body"]], list(smiles = "CC(=O)O"))
})

test_that("pubchem_search warns and returns an empty integer cid tibble on no match", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, list()),
    .package = "ComptoxR"
  )

  expect_warning(
    out <- ComptoxR::pubchem_search("not-a-chemical", cache = FALSE),
    "No PubChem CIDs found"
  )
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
  expect_type(out$cid, "integer")
})

test_that("pubchem_search aborts on non-character or empty query", {
  generated_contract_ensure_package()
  expect_error(ComptoxR::pubchem_search(123, cache = FALSE), "single non-empty character")
  expect_error(ComptoxR::pubchem_search("", cache = FALSE), "single non-empty character")
  expect_error(ComptoxR::pubchem_search(character(0), cache = FALSE), "single non-empty character")
})

# ---- pubchem_synonyms: tidy reshaping + single-CID GET vs bulk POST ----

test_that("pubchem_synonyms tidy=TRUE reshapes Information into a long tibble", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()
  info <- list(list(CID = 2244L, Synonym = c("aspirin", "ASA")))

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, info),
    .package = "ComptoxR"
  )

  out <- ComptoxR::pubchem_synonyms(2244L, cache = FALSE)

  # single CID -> GET branch
  call <- env$calls[[1L]]
  expect_equal(call[["query"]], 2244L)
  expect_null(call[["method"]])
  expect_equal(call[["operation"]], "synonyms")

  expect_s3_class(out, "tbl_df")
  expect_equal(names(out), c("cid", "synonym"))
  expect_type(out$cid, "integer")
  expect_type(out$synonym, "character")
  expect_equal(nrow(out), 2L)
  expect_equal(out$cid, c(2244L, 2244L))
  expect_equal(out$synonym, c("aspirin", "ASA"))
})

test_that("pubchem_synonyms tidy=TRUE drops CIDs with empty Synonym lists", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()
  info <- list(
    list(CID = 2244L, Synonym = c("aspirin")),
    list(CID = 999L, Synonym = NULL)
  )

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, info),
    .package = "ComptoxR"
  )

  out <- ComptoxR::pubchem_synonyms(2244L, cache = FALSE)
  expect_equal(nrow(out), 1L)
  expect_equal(out$cid, 2244L)
  expect_equal(out$synonym, "aspirin")
})

test_that("pubchem_synonyms multiple CIDs use POST batches", {
  generated_contract_ensure_package()
  env <- new.env()
  env$calls <- list()
  info <- list(list(CID = 2244L, Synonym = "aspirin"))

  testthat::local_mocked_bindings(
    generic_pubchem_request = pubchem_mock(env, info),
    .package = "ComptoxR"
  )

  ComptoxR::pubchem_synonyms(c(2244L, 6623L), tidy = FALSE, cache = FALSE)

  call <- env$calls[[1L]]
  expect_equal(call[["method"]], "POST")
  expect_equal(call[["body"]], list(cid = "2244,6623"))
})
