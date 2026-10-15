# Handwritten CRAN-safe tests for chemi_resolver_lookup_bulk.
#
# chemi_resolver_lookup_bulk is the shared resolution root that the
# resolve-then-POST resolver/stdizer wrappers route through. Its trust-boundary
# input validation and helper-boundary contract are behavior the generated
# single-call contract test cannot express (it only drives a valid id vector).
# The collaborator generic_chemi_request is mocked; no network, no API key.
#
# The resolve-then-POST cluster (alerts, hazard_bulk, orderBySimilarity,
# getsimilaritylist, getsimilaritymap, pubchem_section_bulk, getpubchemlist,
# stdizer_chemicals, toxprints_calculate_bulk) is covered
# below against the real branch contract (#219):
# each wrapper resolves via chemi_resolver_lookup_bulk, keeps result=="FOUND"
# entries, maps them to a nested list(chemical = list(sid = chem$chemId %||%
# chem$sid, ...)) payload, and POSTs via generic_chemi_request(tidy = FALSE).
# An empty/all-non-FOUND resolution short-circuits to NULL + warning without
# touching the request helper. Both collaborators are mocked; no network, no key.

if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

test_that("bulk resolver validates ids before options and helper invocation", {
  called <- FALSE
  local_mocked_bindings(generic_chemi_request = function(...) {
    called <<- TRUE
    stop("Helper must not run")
  }, .package = "ComptoxR")
  for (ids in list(NULL, character(), list(), integer())) {
    expect_error(chemi_resolver_lookup_bulk(ids, idsType = stop("Options must not be evaluated")),
      "ids must be a non-empty character vector", fixed = TRUE, class = "rlang_error")
    expect_false(called)
  }
  expect_error(chemi_resolver_lookup_bulk(), 'argument "ids" is missing', fixed = TRUE)
  expect_false(called)
})

test_that("bulk resolver preserves coercion and its complete helper boundary", {
  captured <- NULL
  local_mocked_bindings(generic_chemi_request = function(...) {
    captured <<- list(...)
    "SENTINEL"
  }, .package = "ComptoxR")
  for (ids in list(c(1L, 2L), 0, FALSE, TRUE, factor(c("b", "a")), list("one", "two"),
    c("one", "one", NA_character_, ""), "caf\u00e9 +/&")) {
    expect_identical(chemi_resolver_lookup_bulk(ids), "SENTINEL")
    expect_identical(captured, list(query = as.character(ids), endpoint = "resolver/lookup",
      options = list(idsType = "AnyId", fuzzy = "Not", mol = FALSE), sid_label = "ids",
      array_payload = TRUE, tidy = TRUE))
  }
  for (value in list(NULL, FALSE, 0, "unknown-enum", list())) {
    chemi_resolver_lookup_bulk("one", idsType = value, fuzzy = value, mol = value,
      filters = value, format = value, tidy = FALSE)
    options <- list(idsType = value, fuzzy = value, mol = value)
    if (!is.null(value)) options <- c(options, list(filters = value, format = value))
    expect_identical(captured$options, options)
    expect_identical(captured$tidy, FALSE)
  }
  for (setting in c(NA_character_, "0", "2", "1000")) {
    withr::with_envvar(c(batch_limit = setting), {
      chemi_resolver_lookup_bulk(c("one", "two", "three"))
      expect_identical(captured$query, c("one", "two", "three"))
      expect_false("batch_limit" %in% names(captured))
    })
  }
  chemi_resolver_lookup_bulk("one", filters = list(flag = FALSE, count = 0), format = "JSON")
  expect_identical(captured$options, list(idsType = "AnyId", fuzzy = "Not", mol = FALSE,
    filters = list(flag = FALSE, count = 0), format = "JSON"))
})

# ---- resolve-then-POST cluster (#219) ------------------------------------

# Endpoint each wrapper must POST to after resolution.
resolver_cluster <- list(
  chemi_alerts = "alerts",
  chemi_hazard_bulk = "hazard",
  chemi_resolver_orderBySimilarity = "resolver/orderBySimilarity",
  chemi_resolver_getsimilaritylist = "resolver/getsimilaritylist",
  chemi_resolver_getsimilaritymap = "resolver/getsimilaritymap",
  chemi_resolver_pubchem_section_bulk = "resolver/pubchem-section",
  chemi_resolver_getpubchemlist = "resolver/getpubchemlist",
  chemi_stdizer_chemicals = "stdizer/chemicals",
  chemi_toxprints_calculate_bulk = "toxprints/calculate"
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
          if (nm == "chemi_resolver_getsimilaritymap") {
            return(list(
              order = list(
                list(chemical = list(sid = "DTXSID-A", name = "A")),
                list(chemical = list(sid = "SID-ONLY", name = "B"))
              ),
              similarity = list(
                list(list(sim = 0), list(sim = 0.25)),
                list(list(sim = 0.25), list(sim = 0))
              )
            ))
          }
          "SENTINEL"
        },
        .package = "ComptoxR"
      )

      res <- get(nm, envir = asNamespace("ComptoxR"))(query = c("50-00-0", "x"))

      # Post-response formatters transform the raw helper result.
      if (nm == "chemi_resolver_getsimilaritymap") {
        expect_s3_class(res$hc, "hclust")
      } else if (nm != "chemi_hazard_bulk") {
        expect_identical(res, "SENTINEL")
      }
      expect_identical(captured$endpoint, endpoint)
      expect_false(captured$tidy)
      expect_length(captured$chemicals, 2L)
      if (nm == "chemi_resolver_getsimilaritymap") {
        expect_identical(captured$chemicals[[1]]$sid, "DTXSID-A")
        expect_identical(captured$chemicals[[2]]$sid, "SID-ONLY")
      } else {
        expect_identical(captured$chemicals[[1]]$chemical$sid, "DTXSID-A")
        expect_identical(captured$chemicals[[2]]$chemical$sid, "SID-ONLY")
      }
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
