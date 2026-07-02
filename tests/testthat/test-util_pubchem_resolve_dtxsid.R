comptoxr_internal_env <- function() {
  get(".ComptoxREnv", envir = asNamespace("ComptoxR"))
}

clear_pubchem_resolve_cache <- function() {
  env <- comptoxr_internal_env()
  if (exists("pubchem_cid_map", envir = env, inherits = FALSE)) {
    rm("pubchem_cid_map", envir = env)
  }
}

mock_pubchem_synonyms <- function(cid, tidy = FALSE, cache = TRUE) {
  lapply(as.integer(cid), function(id) {
    switch(
      as.character(id),
      "2244" = list(CID = 2244L, Synonym = c("aspirin", "DTXSID7020182", "50-78-2")),
      "6623" = list(CID = 6623L, Synonym = c("bisphenol A", "80-05-7")),
      "999999999" = list(CID = 999999999L, Synonym = c("unresolvable compound")),
      list(CID = id, Synonym = character())
    )
  })
}

test_that("util_pubchem_resolve_dtxsid extracts DTXSID directly from PubChem synonyms", {
  clear_pubchem_resolve_cache()
  on.exit(clear_pubchem_resolve_cache(), add = TRUE)

  testthat::local_mocked_bindings(
    pubchem_synonyms = mock_pubchem_synonyms,
    ct_chemical_search_equal_bulk = function(...) stop("CAS fallback should not be called"),
    .package = "ComptoxR"
  )

  result <- util_pubchem_resolve_dtxsid(2244, cache = FALSE)

  expect_type(result, "character")
  expect_named(result, "2244")
  expect_equal(result[["2244"]], "DTXSID7020182")
})

test_that("util_pubchem_resolve_dtxsid uses CAS fallback for unresolved synonyms", {
  clear_pubchem_resolve_cache()
  on.exit(clear_pubchem_resolve_cache(), add = TRUE)

  testthat::local_mocked_bindings(
    pubchem_synonyms = mock_pubchem_synonyms,
    ct_chemical_search_equal_bulk = function(casrn) {
      expect_equal(casrn, "80-05-7")
      tibble::tibble(casrn = "80-05-7", dtxsid = "DTXSID7020630")
    },
    .package = "ComptoxR"
  )

  result <- util_pubchem_resolve_dtxsid(c(2244, 6623), cache = FALSE)

  expect_type(result, "character")
  expect_named(result, c("2244", "6623"))
  expect_equal(result[["2244"]], "DTXSID7020182")
  expect_equal(result[["6623"]], "DTXSID7020630")
})

test_that("util_pubchem_resolve_dtxsid returns NA for unresolvable CIDs", {
  clear_pubchem_resolve_cache()
  on.exit(clear_pubchem_resolve_cache(), add = TRUE)

  testthat::local_mocked_bindings(
    pubchem_synonyms = mock_pubchem_synonyms,
    ct_chemical_search_equal_bulk = function(...) tibble::tibble(casrn = character(), dtxsid = character()),
    .package = "ComptoxR"
  )

  expect_warning(
    result <- util_pubchem_resolve_dtxsid(999999999, cache = FALSE),
    "could not be resolved"
  )
  expect_true(is.na(result[["999999999"]]))
})

test_that("util_pubchem_resolve_dtxsid caches repeated session lookups", {
  clear_pubchem_resolve_cache()
  on.exit(clear_pubchem_resolve_cache(), add = TRUE)

  calls <- 0L
  testthat::local_mocked_bindings(
    pubchem_synonyms = function(cid, tidy = FALSE, cache = TRUE) {
      calls <<- calls + 1L
      mock_pubchem_synonyms(cid, tidy = tidy, cache = cache)
    },
    ct_chemical_search_equal_bulk = function(...) stop("CAS fallback should not be called"),
    .package = "ComptoxR"
  )

  result1 <- util_pubchem_resolve_dtxsid(2244, cache = TRUE)
  result2 <- util_pubchem_resolve_dtxsid(2244, cache = TRUE)

  expect_equal(result1, result2)
  expect_equal(calls, 1L)
})

test_that("CAS validation uses existing is_cas() function", {
  expect_true(is_cas("50-78-2"))
  expect_true(is_cas("80-05-7"))
  expect_true(is_cas("7732-18-5"))

  expect_false(is_cas("50-78-3"))
  expect_false(is_cas("80-05-8"))
  expect_false(is_cas("not-a-cas"))
  expect_false(is_cas("12345"))
})

test_that("util_pubchem_resolve_dtxsid rejects empty input", {
  expect_error(util_pubchem_resolve_dtxsid(integer(0)))
})
