# Handwritten CRAN-safe tests for chemi_resolver_lookup_bulk.
#
# chemi_resolver_lookup_bulk is the shared resolution root that the
# resolve-then-POST resolver/stdizer wrappers route through. Its trust-boundary
# input validation and helper-boundary contract are behavior the generated
# single-call contract test cannot express (it only drives a valid id vector).
# The collaborator generic_chemi_request is mocked; no network, no API key.
#
# The resolve-then-POST cluster (orderBySimilarity, getsimilaritylist,
# getsimilaritymap, pubchem_section_bulk, getpubchemlist, universalharvest_cart,
# stdizer_chemicals) is covered below against the real branch contract (#219):
# each wrapper resolves via chemi_resolver_lookup_bulk, keeps result=="FOUND"
# entries, maps them to a nested list(chemical = list(sid = chem$chemId %||%
# chem$sid, ...)) payload, and POSTs via generic_chemi_request(tidy = FALSE).
# An empty/all-non-FOUND resolution short-circuits to NULL + warning without
# touching the request helper. Both collaborators are mocked; no network, no key.

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

# ---- resolve-then-POST cluster (#219) ------------------------------------

# Endpoint each wrapper must POST to after resolution.
resolver_cluster <- list(
  chemi_resolver_orderBySimilarity = "resolver/orderBySimilarity",
  chemi_resolver_getsimilaritylist = "resolver/getsimilaritylist",
  chemi_resolver_getsimilaritymap = "resolver/getsimilaritymap",
  chemi_resolver_pubchem_section_bulk = "resolver/pubchem-section",
  chemi_resolver_getpubchemlist = "resolver/getpubchemlist",
  chemi_resolver_universalharvest_cart = "resolver/universalharvest_cart",
  chemi_stdizer_chemicals = "stdizer/chemicals"
)

# A FOUND-shaped lookup record whose chemical carries the canonical chemId key.
found_record <- function(chem_id = "DTXSID-A") {
  list(
    result = "FOUND",
    chemical = list(
      chemId = chem_id,
      canonicalSmiles = "C",
      casrn = "50-00-0",
      inchi = "InChI=1S/CH2O",
      inchiKey = "WSFSSNUMVMOOMR-UHFFFAOYSA-N",
      name = "formaldehyde"
    )
  )
}

# A FOUND record missing chemId, so sid must come from the %||% fallback.
sid_only_record <- function(sid = "SID-ONLY") {
  list(result = "FOUND", chemical = list(sid = sid, smiles = "CC"))
}

for (wrapper_name in names(resolver_cluster)) {
  local({
    nm <- wrapper_name
    endpoint <- resolver_cluster[[nm]]

    test_that(paste0(nm, " resolves, maps sid via chemId %||% sid, and POSTs to ", endpoint), {
      captured <- NULL
      local_mocked_bindings(
        chemi_resolver_lookup_bulk = function(...) list(found_record(), sid_only_record()),
        generic_chemi_request = function(...) {
          captured <<- list(...)
          "SENTINEL"
        },
        .package = "ComptoxR"
      )

      res <- get(nm, envir = asNamespace("ComptoxR"))(query = c("50-00-0", "x"))

      expect_identical(res, "SENTINEL")
      expect_identical(captured$endpoint, endpoint)
      expect_false(captured$tidy)
      expect_length(captured$chemicals, 2L)
      expect_identical(captured$chemicals[[1]]$chemical$sid, "DTXSID-A")
      expect_identical(captured$chemicals[[2]]$chemical$sid, "SID-ONLY")
    })

    test_that(paste0(nm, " short-circuits to NULL + warning when nothing resolves"), {
      called <- FALSE
      local_mocked_bindings(
        chemi_resolver_lookup_bulk = function(...) {
          list(list(result = "NOT_FOUND"), list(result = "ERROR"))
        },
        generic_chemi_request = function(...) {
          called <<- TRUE
          "SHOULD-NOT-RUN"
        },
        .package = "ComptoxR"
      )

      expect_warning(
        res <- get(nm, envir = asNamespace("ComptoxR"))(query = "nope"),
        "No chemicals could be resolved"
      )
      expect_null(res)
      expect_false(called)
    })
  })
}

test_that("chemi_resolver_getpubchemlist forwards pagination args to generic_chemi_request", {
  captured <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) list(found_record()),
    generic_chemi_request = function(...) {
      captured <<- list(...)
      "SENTINEL"
    },
    .package = "ComptoxR"
  )

  chemi_resolver_getpubchemlist(query = "50-00-0")

  expect_true(captured$paginate)
  expect_identical(captured$max_pages, 100)
  expect_identical(captured$pagination_strategy, "page_size")
})
