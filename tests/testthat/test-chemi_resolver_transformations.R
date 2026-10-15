# Frozen behavior of the three retained #337 wrappers. All collaborators are mocked.
if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

map_response <- function() {
  list(
    order = list(list(chemical = list(sid = "A", name = "first")), list(chemical = list(name = "second"))),
    similarity = list(list(list(sim = 0), list(value = 0.25)), list(list(sim = 0.25), list(sim = 0)))
  )
}

test_that("similarity map keeps resolver arguments, flat chemicals, omitted options and sort", {
  calls <- list()
  lookup <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      lookup <<- list(...)
      list(
        list(result = "FOUND", chemical = list(chemId = "A", canonicalSmiles = "C", name = "first")),
        list(result = "NOT_FOUND"),
        list(result = "FOUND", chemical = list(sid = "B", smiles = "CC"))
      )
    },
    generic_chemi_request = function(...) {
      calls[[length(calls) + 1L]] <<- list(...)
      map_response()
    },
    .package = "ComptoxR"
  )
  expected_chemicals <- list(
    list(sid = "A", smiles = "C", casrn = NULL, inchi = NULL, inchiKey = NULL, name = "first"),
    list(sid = "B", smiles = "CC", casrn = NULL, inchi = NULL, inchiKey = NULL, name = NULL)
  )
  result <- chemi_resolver_getsimilaritymap(c("one", "two"))
  expect_identical(lookup, list(ids = c("one", "two"), idsType = "AnyId", tidy = FALSE))
  expect_identical(
    calls[[1]],
    list(
      query = NULL,
      endpoint = "resolver/getsimilaritymap",
      options = list(),
      tidy = FALSE,
      chemicals = expected_chemicals,
      sort = "false"
    )
  )
  expect_identical(names(result), c("mol_names", "similarity", "hc"))
  expect_identical(result$similarity, matrix(c(0, .25, .25, 0), 2, dimnames = list(c("A", "second"), c("A", "second"))))
  expect_identical(result$hc$method, "complete")
  for (value in list(NULL, FALSE, 0, TRUE, "UPPER")) {
    chemi_resolver_getsimilaritymap("one", idType = value, section = value, sort = value, format = "raw")
    expect_identical(lookup$idsType, if (is.null(value)) "AnyId" else value)
    call <- calls[[length(calls)]]
    expect_identical(call$options, if (is.null(value)) list() else list(section = value))
    expect_identical(call$sort, if (is.null(value)) NULL else tolower(as.character(value)))
    expect_identical(call$chemicals, expected_chemicals)
  }
  for (query in list(NULL, FALSE, 0, character())) {
    chemi_resolver_getsimilaritymap(query, format = "raw")
    expect_identical(lookup$ids, query)
  }
  expect_identical(chemi_resolver_getsimilaritymap("one", hclust_method = "single")$hc$method, "single")
  expect_identical(
    chemi_resolver_getsimilaritymap("one", format = "long"),
    tibble::tibble(parent = c("A", "second"), child = c("second", "A"), value = c(.25, .25))
  )
  expect_identical(chemi_resolver_getsimilaritymap("one", format = "raw"), map_response())
  expect_identical(chemi_resolver_getsimilaritymap("one", hclust_method = NULL, format = NULL)$hc$method, "complete")
  expect_error(chemi_resolver_getsimilaritymap(), 'argument "query" is missing', fixed = TRUE)
  expect_error(chemi_resolver_getsimilaritymap("one", format = FALSE), class = "comptoxr_post_response_hook_error")
  expect_error(
    chemi_resolver_getsimilaritymap("one", hclust_method = "invalid"),
    class = "comptoxr_post_response_hook_error"
  )
})

test_that("similarity map preserves exact pre/post states, partial updates and skip", {
  stages <- calls <- list()
  skip <- FALSE
  local_mocked_bindings(
    run_hook = function(fn, stage, data) {
      expect_identical(fn, "chemi_resolver_getsimilaritymap")
      stages[[length(stages) + 1L]] <<- list(stage = stage, data = data)
      if (stage == "post_response") {
        return(data$result)
      }
      if (skip) {
        return(list(skip_request = TRUE, result = list(skipped = FALSE, count = 0)))
      }
      list(params = list(section = 0, query = NULL, chemicals = list(list(sid = "resolved")), format = "raw"))
    },
    generic_chemi_request = function(...) {
      calls[[length(calls) + 1L]] <<- list(...)
      "response"
    },
    .package = "ComptoxR"
  )
  expect_identical(chemi_resolver_getsimilaritymap("one"), "response")
  expect_identical(
    stages[[1]]$data,
    list(
      params = list(
        query = "one",
        idType = "AnyId",
        section = NULL,
        sort = FALSE,
        hclust_method = "complete",
        format = c("cluster", "long", "raw"),
        chemicals = NULL
      )
    )
  )
  expect_identical(
    calls[[1]],
    list(
      query = NULL,
      endpoint = "resolver/getsimilaritymap",
      options = list(section = 0),
      tidy = FALSE,
      chemicals = list(list(sid = "resolved")),
      sort = "false"
    )
  )
  expect_identical(
    stages[[2]]$data,
    list(
      result = "response",
      params = list(
        query = NULL,
        idType = "AnyId",
        section = 0,
        sort = FALSE,
        hclust_method = "complete",
        format = "raw"
      )
    )
  )
  skip <- TRUE
  expect_identical(chemi_resolver_getsimilaritymap("one"), list(skipped = FALSE, count = 0))
  expect_length(stages, 3L)
  expect_length(calls, 1L)
})

test_that("similarity map skips unresolved inputs and wraps hook errors, not transport errors", {
  lookup_calls <- 0L
  response <- list(list(result = "NOT_FOUND"))
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      lookup_calls <<- lookup_calls + 1L
      if (inherits(response, "error")) {
        stop(response)
      }
      response
    },
    generic_chemi_request = function(...) stop("transport sentinel"),
    .package = "ComptoxR"
  )
  expect_warning(
    expect_null(chemi_resolver_getsimilaritymap("one", format = "invalid")),
    "No chemicals could be resolved"
  )
  response <- simpleError("resolver sentinel")
  expect_error(chemi_resolver_getsimilaritymap("one"), class = "comptoxr_pre_request_hook_error")
  expect_identical(lookup_calls, 3L) # first attempt plus fallback
  response <- list(list(result = "FOUND", chemical = list(sid = "A")))
  expect_error(chemi_resolver_getsimilaritymap("one"), "transport sentinel", fixed = TRUE)
})

test_that("ClassyFire selects and renames available columns while preserving empty results", {
  response <- tibble::tibble()
  call <- NULL
  local_mocked_bindings(
    generic_request = function(...) {
      call <<- list(...)
      response
    },
    run_hook = function(...) stop("no hooks in this wrapper"),
    .package = "ComptoxR"
  )
  for (query in list(NULL, character(), FALSE, 0, c("one", "two"))) {
    expect_identical(chemi_classyfire(query), response)
    expect_identical(
      call,
      list(
        query = query,
        endpoint = "amos/get_classification_for_dtxsid/",
        method = "GET",
        batch_limit = 1,
        server = "chemi_burl",
        auth = FALSE
      )
    )
  }
  expect_error(chemi_classyfire(), 'argument "query" is missing', fixed = TRUE)
  for (id in c("query", "value", "sid")) {
    response <- tibble::tibble(kingdom = "K", superklass = "S", klass = "C", subklass = "SC", discarded = TRUE)
    response[[id]] <- "one"
    expect_identical(
      chemi_classyfire("one"),
      tibble::tibble(dtxsid = "one", kingdom = "K", superclass = "S", class = "C", subclass = "SC")
    )
  }
  response <- tibble::tibble(query = "q", value = "v", sid = "s", klass = "C")
  expect_identical(chemi_classyfire("one"), tibble::tibble(dtxsid1 = "q", dtxsid2 = "v", dtxsid3 = "s", class = "C"))
  response <- tibble::tibble(extra = 0)
  expect_identical(chemi_classyfire("one"), tibble::new_tibble(list(), nrow = 1L))
  response <- tibble::tibble(query = character(), extra = logical())
  expect_identical(chemi_classyfire("one"), response)
  response <- NULL
  expect_error(chemi_classyfire("one"), "argument is of length zero")
})

test_that("RQ codes preserves mocked transformations, NULL results and parsing errors", {
  response <- NULL
  call <- NULL
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      call <<- list(...)
      response
    },
    run_hook = function(...) stop("no hooks in this wrapper"),
    .package = "ComptoxR"
  )
  for (empty in list(NULL, list(), list(list(rqCode = NULL)), list(list(other = FALSE)))) {
    response <- empty
    expect_null(chemi_safety_rqcodes())
    expect_identical(call, list(query = NULL, endpoint = "safety/rqcodes", tidy = FALSE))
  }
  response <- list(
    list(rqCode = list(code = "A", rq = "1,000 (454)", flag = FALSE, count = 0)),
    list(rqCode = NULL),
    list(rqCode = list(code = "B", rq = "0 (0)", flag = FALSE, count = 0))
  )
  expect_identical(
    chemi_safety_rqcodes(),
    tibble::tibble(code = c("A", "B"), rq_lbs = c(1000, 0), rq_kgs = c(454, 0), flag = c(FALSE, FALSE), count = c(0, 0))
  )
  for (rq in list("invalid", "1 2 3", NULL)) {
    response <- list(list(rqCode = list(code = "A", rq = rq)))
    expect_error(chemi_safety_rqcodes())
  }
  response <- list(list(rqCode = list(rq = "bad (bad)")))
  expect_warning(result <- chemi_safety_rqcodes(), "NAs introduced by coercion")
  expect_true(all(is.na(result)))
  expect_error(chemi_safety_rqcodes(NULL), "unused argument")
})

test_that("RQ codes retains its empty-query rejection and both wrappers propagate helper errors", {
  withr::local_envvar(c(chemi_burl = "http://127.0.0.1:1", run_debug = "FALSE"))
  local_mocked_bindings(.endpoint_url = function(...) "http://127.0.0.1:1", .package = "ComptoxR")
  expect_error(
    chemi_safety_rqcodes(),
    "Either query or chemicals parameter must be provided.",
    fixed = TRUE,
    class = "rlang_error"
  )
  local_mocked_bindings(
    generic_request = function(...) stop("request sentinel"),
    generic_chemi_request = function(...) stop("request sentinel"),
    .package = "ComptoxR"
  )
  expect_error(chemi_classyfire("one"), "request sentinel", fixed = TRUE)
  expect_error(chemi_safety_rqcodes(), "request sentinel", fixed = TRUE)
})

test_that("similarity map retries resolution without idType and preserves real empty-input errors", {
  for (query in list(NULL, character(), list())) {
    expect_error(chemi_resolver_getsimilaritymap(query), class = "comptoxr_pre_request_hook_error")
  }
  calls <- list()
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      calls[[length(calls) + 1L]] <<- list(...)
      if (length(calls) == 1L) {
        stop("first resolver attempt")
      }
      list(list(result = "FOUND", chemical = list(sid = "A")))
    },
    generic_chemi_request = function(...) "raw result",
    .package = "ComptoxR"
  )
  expect_identical(chemi_resolver_getsimilaritymap("one", idType = "CAS", format = "raw"), "raw result")
  expect_identical(calls, list(list(ids = "one", idsType = "CAS", tidy = FALSE), list(ids = "one", tidy = FALSE)))
})
