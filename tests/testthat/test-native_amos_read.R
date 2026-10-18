# Reviewed operations covered by captured native transport contracts.
# chemi_amos_spectral_entropy
# chemi_amos_entropy_similarity
# chemi_amos_spectrum_count_for_methodology
# chemi_amos_mass_range
# chemi_amos_next_level_classification
# chemi_amos_substances_for_classification
# chemi_amos_all_similarities
# chemi_amos_max_similarity
# chemi_amos_mass_spectrum_similarity
test_that("reviewed AMOS JSON operations preserve captured requests and results", {
  requests <- list()
  bytes <- raw()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"), body = bytes)
  }, .package = "httr2")
  for (case in readRDS(test_path("fixtures", "native-amos-read.rds"))) {
    fn <- get(case$wrapper, asNamespace("ComptoxR"))
    bytes <- case$body
    result <- suppressMessages(do.call(fn, case$args))
    expect_identical(result, case$result, info = case$wrapper)
    request <- tail(requests, 1L)[[1L]]
    expect_identical(request$method, "POST")
    expect_true(endsWith(request$url, sub("^POST ", "", case$operation)))
    expect_identical(request$headers$Accept, "application/json")
    expect_false("x-api-key" %in% names(request$headers))
    expect_identical(jsonlite::toJSON(request$body$data, auto_unbox = TRUE,
      null = "null", digits = 22), case$wire, info = case$wrapper)
    args <- Filter(Negate(is.null), case$args[names(formals(fn))])
    expect_identical(suppressMessages(do.call(fn, unname(args))), result)
  }
})

test_that("AMOS read HTTP, credential and transport errors remain hard", {
  status <- 404L
  local_mocked_bindings(req_perform = function(req, ...) {
    response <- httr2::response(status_code = status,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('{}'))
    is_error <- req$policies$error_is_error
    if (is.null(is_error) || isTRUE(is_error(response))) {
      rlang::abort("HTTP failure", class = c("httr2_http", "httr2_error"), resp = response)
    }
    response
  }, .package = "httr2")
  for (case in readRDS(test_path("fixtures", "native-amos-read.rds"))) {
    fn <- get(case$wrapper, asNamespace("ComptoxR"))
    for (code in c(404L, 500L)) {
      status <- code
      expect_error(suppressMessages(do.call(fn, case$args)), as.character(code))
    }
    status <- 401L
    expect_error(suppressMessages(do.call(fn, case$args)), class = "specmill_call_error")
  }
  local_mocked_bindings(req_perform = function(...) stop("transport sentinel"),
    .package = "httr2")
  expect_error(chemi_amos_spectral_entropy(list(c(100, 1))),
    "HTTP request failed before a response")
})
