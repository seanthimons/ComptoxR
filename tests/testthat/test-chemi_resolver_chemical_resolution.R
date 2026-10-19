# CRAN-safe checks for the shared chemi_resolver_lookup_bulk boundary.
# Similarity reference/candidate hooks are covered in test-similarity_list.R.

test_that("bulk resolver validates ids before options and HTTP", {
  called <- FALSE
  local_mocked_bindings(req_perform = function(...) {
    called <<- TRUE
    stop("HTTP must not run")
  }, .package = "httr2")
  for (ids in list(NULL, character(), list(), integer())) {
    expect_error(chemi_resolver_lookup_bulk(ids, idsType = stop("Options must not be evaluated")),
      "ids must be a non-empty character vector", fixed = TRUE, class = "rlang_error")
    expect_false(called)
  }
  expect_error(chemi_resolver_lookup_bulk(), 'argument "ids" is missing', fixed = TRUE)
  expect_error(chemi_resolver_lookup_bulk(c("", NA), idsType = stop("idsType evaluated")),
               "idsType evaluated", fixed = TRUE)
  expect_error(chemi_resolver_lookup_bulk(c("", NA), tidy = stop("tidy evaluated")),
               "Either query or chemicals parameter must be provided.", fixed = TRUE)
  expect_false(called)
})

test_that("bulk resolver preserves captured results and complete JSON requests", {
  cases <- readRDS(test_path("fixtures/native-resolver-lookup.rds"))
  withr::local_options(ComptoxR.chemi_burl = "https://hcd.rtpnc.epa.gov")
  for (case in cases) local({
    requests <- list()
    local_mocked_bindings(req_perform = function(req, ...) {
      requests[[length(requests) + 1L]] <<- req
      httr2::response(status_code = 200L,
        headers = list(`Content-Type` = "application/json"), body = charToRaw(case$json))
    }, .package = "httr2")
    expect_identical(do.call(chemi_resolver_lookup_bulk, case$args), case$result)
    expect_length(requests, 1L)
    req <- requests[[1L]]
    wire <- list(method = req$method, url = req$url, accept = req$headers$Accept,
      body = jsonlite::toJSON(req$body$data, auto_unbox = TRUE, null = "null", digits = 22))
    expect_identical(wire, case$wire)
  })
})

test_that("bulk resolver evaluates tidy only after transport and memoizes its promise", {
  failed <- TRUE
  requests <- 0L
  local_mocked_bindings(req_perform = function(req, ...) {
    requests <<- requests + 1L
    if (failed) stop("transport sentinel")
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('[{"value":1}]'))
  }, .package = "httr2")
  error <- tryCatch(chemi_resolver_lookup_bulk("one", tidy = stop("tidy evaluated")),
                    error = identity)
  expect_s3_class(error, "error")
  expect_false(grepl("tidy evaluated", conditionMessage(error), fixed = TRUE))
  expect_identical(requests, 1L)
  failed <- FALSE
  count <- 0L
  result <- chemi_resolver_lookup_bulk("one", tidy = { count <- count + 1L; TRUE })
  expect_identical(count, 1L)
  expect_identical(result, tibble::tibble(dtxsid = "one", value = 1L))
})

test_that("bulk resolver preserves coercion, NULL option slots and unbatched projection", {
  captured <- NULL
  local_mocked_bindings(.ct_request = function(...) {
    captured <<- list(...)
    "SENTINEL"
  }, .package = "ComptoxR")
  for (ids in list(c(1L, 2L), 0, FALSE, TRUE, factor(c("b", "a")), list("one", "two"),
    c("one", "one", NA_character_, ""), "caf\u00e9 +/&")) {
    expect_identical(chemi_resolver_lookup_bulk(ids), "SENTINEL")
    clean <- unique(as.character(ids))
    clean <- clean[!is.na(clean) & clean != ""]
    expect_identical(captured$body, list(ids = as.list(clean),
      idsType = "AnyId", fuzzy = "Not", mol = FALSE))
  }
  for (value in list(NULL, FALSE, 0, "unknown-enum", list())) {
    chemi_resolver_lookup_bulk("one", idsType = value, fuzzy = value, mol = value,
      filters = value, format = value, tidy = FALSE)
    expected <- list(ids = list("one"), idsType = value, fuzzy = value, mol = value)
    if (!is.null(value)) expected <- c(expected, list(filters = value, format = value))
    expect_identical(captured$body, expected)
  }
  for (setting in c(NA_character_, "0", "2", "1000")) {
    withr::with_envvar(c(batch_limit = setting), {
      chemi_resolver_lookup_bulk(c("one", "two", "three"))
      expect_identical(captured$body$ids, list("one", "two", "three"))
    })
  }
})
