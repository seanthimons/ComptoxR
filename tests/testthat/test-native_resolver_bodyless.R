test_that("reviewed bodyless resolver preserves static list results and requests", {
  fixture <- readRDS(test_path("fixtures", "native-resolver-bodyless.rds"))
  requests <- list()
  body <- raw()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"), body = body)
  }, .package = "httr2")
  for (case in fixture$cases) {
    body <- charToRaw(case$body)
    warnings <- character()
    result <- withCallingHandlers(chemi_resolver_ghs_list_count(),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    expect_identical(result, case$result)
    expect_identical(warnings, case$warnings)
  }
  body <- fixture$production$body
  expect_identical(chemi_resolver_ghs_list_count(), fixture$production$result)
  expect_length(fixture$production$result, 79L)
  expect_length(formals(chemi_resolver_ghs_list_count), 0L)
  for (request in requests) {
    expect_identical(request$method, "GET")
    expect_true(endsWith(request$url, "/api/resolver/ghs-list-count"))
    expect_null(request$body)
    expect_identical(request$headers$Accept, "application/json")
    expect_false("x-api-key" %in% names(request$headers))
  }
})

test_that("bodyless resolver keeps received HTTP failures separate from hard errors", {
  status <- 404L
  local_mocked_bindings(req_perform = function(...) {
    httr2::response(status_code = status,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('{}'))
  }, .package = "httr2")
  for (code in c(404L, 500L)) {
    status <- code
    expect_warning(result <- chemi_resolver_ghs_list_count(),
      paste0("failed for.*_static_.*status ", code))
    expect_identical(result, list(NULL))
  }
  status <- 401L
  expect_error(chemi_resolver_ghs_list_count(), class = "specmill_call_error")
  local_mocked_bindings(req_perform = function(...) stop("transport sentinel"),
    .package = "httr2")
  expect_error(chemi_resolver_ghs_list_count(), "HTTP request failed before a response")
})
