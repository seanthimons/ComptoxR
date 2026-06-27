# Handwritten CRAN-safe tests for chemi_resolver_lookup_bulk.
#
# chemi_resolver_lookup_bulk is the shared resolution root that the
# resolve-then-POST resolver/stdizer wrappers route through. Its trust-boundary
# input validation and helper-boundary contract are behavior the generated
# single-call contract test cannot express (it only drives a valid id vector).
# The collaborator generic_chemi_request is mocked; no network, no API key.
#
# NOTE: the resolve-then-POST cluster (orderBySimilarity, getsimilaritylist,
# getsimilaritymap, pubchem_section_bulk, getpubchemlist, universalharvest_cart,
# stdizer_chemicals) is intentionally NOT covered here. The branch source for
# those wrappers has diverged from the shipped package (it resolves via
# chemi_resolver_lookup_bulk + a result=="FOUND" filter + a nested
# list(chemical = list(sid = chem$chemId %||% chem$sid, ...)) payload, and
# chemi_resolver_getpubchemlist references an undefined `all_pages` symbol).
# That divergence is a source concern tracked separately (#219); locking tests
# to it now would be premature. See the issue note for the full finding.

test_that("chemi_resolver_lookup_bulk aborts on empty/NULL ids before any request", {
  expect_error(chemi_resolver_lookup_bulk(NULL), "non-empty character vector")
  expect_error(chemi_resolver_lookup_bulk(character(0)), "non-empty character vector")
})

test_that("chemi_resolver_lookup_bulk coerces ids to character and crosses the helper boundary", {
  captured <- NULL
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured <<- list(...)
      "SENTINEL"
    },
    .package = "ComptoxR"
  )

  res <- chemi_resolver_lookup_bulk(ids = c(1L, 2L))

  expect_identical(res, "SENTINEL")
  expect_type(captured$query, "character")
  expect_identical(captured$query, c("1", "2"))
  expect_identical(captured$endpoint, "resolver/lookup")
  expect_identical(captured$sid_label, "ids")
  expect_true(captured$array_payload)
})
