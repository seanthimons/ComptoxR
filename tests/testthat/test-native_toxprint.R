test_that("toxprint preserves reviewed JSON request projections and results", {
  fixture <- readRDS(test_path("fixtures", "native-toxprint.rds"))
  requests <- list()
  payload <- "[]"
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"), body = charToRaw(payload))
  }, .package = "httr2")
  for (case in fixture$cases) {
    payload <- case$payload
    expect_identical(withVisible(do.call(chemi_toxprint, case$args)), case$result)
    request <- tail(requests, 1L)[[1L]]
    expect_identical(request$method, case$wire$method)
    expect_identical(httr2::url_parse(request$url)$path, case$wire$path)
    expect_identical(request$headers$Accept, case$wire$accept)
    expect_false("x-api-key" %in% names(request$headers))
    expect_identical(jsonlite::fromJSON(as.character(jsonlite::toJSON(
      request$body$data, auto_unbox = TRUE, null = "null", digits = 22)),
      simplifyVector = FALSE),
      jsonlite::fromJSON(rawToChar(case$wire$body), simplifyVector = FALSE))
    expect_identical(withVisible(do.call(chemi_toxprint, unname(case$args))), case$result)
  }
})

test_that("toxprint rejects empty input before evaluating options or HTTP", {
  local_mocked_bindings(.ct_request = function(...) stop("HTTP called"),
    .package = "ComptoxR")
  for (query in list(NULL, character(), c("", NA_character_))) {
    expect_error(chemi_toxprint(query, odds_ratio = stop("option evaluated")),
      "Either query or chemicals parameter must be provided")
  }
})

test_that("toxprint forwards helper values and visibility", {
  fixture <- readRDS(test_path("fixtures", "native-toxprint.rds"))
  old <- eval(fixture$legacy[[3L]], asNamespace("ComptoxR"))
  expect_identical(formals(chemi_toxprint), formals(old))
  for (value in list(NULL, FALSE, 0, list(score = 0, flag = FALSE, nested = list(absent = NULL)))) {
    local({
      local_mocked_bindings(generic_chemi_request = function(...) invisible(value),
        .ct_request = function(...) invisible(value), .package = "ComptoxR")
      expect_identical(withVisible(chemi_toxprint("one")), withVisible(old("one")))
    })
  }
})

test_that("toxprint keeps HTTP, credential and transport failures hard", {
  status <- 404L
  local_mocked_bindings(req_perform = function(...) {
    httr2::response(status_code = status,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('{}'))
  }, .package = "httr2")
  for (code in c(404L, 500L)) {
    status <- code
    expect_error(chemi_toxprint("one"), as.character(code))
  }
  status <- 401L
  expect_error(chemi_toxprint("one"), class = "specmill_call_error")
  local_mocked_bindings(req_perform = function(...) stop("transport sentinel"),
    .package = "httr2")
  expect_error(chemi_toxprint("one"), "HTTP request failed before a response")
})
