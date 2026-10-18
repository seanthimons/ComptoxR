test_that("list-all HTTP failures remain hard and skip post-response formatting", {
  withr::local_envvar(ctx_api_key = "local-policy-key")
  for (status in c(404L, 500L)) {
    local_mocked_bindings(req_perform = function(req, ...) {
      httr2::response(status_code = status,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"error":"missing"}'))
    }, .package = "httr2")
    for (args in list(list(), list(return_dtxsid = TRUE),
        list(return_dtxsid = TRUE, coerce = TRUE))) {
      expect_error(suppressMessages(do.call(ct_chemical_list_all, args)),
        paste("HTTP", status))
    }
  }
})

test_that("list-all authentication and transport failures remain hard errors", {
  withr::local_envvar(ctx_api_key = "local-policy-key")
  local_mocked_bindings(req_perform = function(req, ...) {
    httr2::response(status_code = 401L,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('{}'))
  }, .package = "httr2")
  expect_error(ct_chemical_list_all(), class = "specmill_call_error")
  local_mocked_bindings(req_perform = function(...) stop("transport sentinel"),
    .package = "httr2")
  expect_error(ct_chemical_list_all(), "before a response was received")
})

test_that("list-all failed responses still reach the API status observer", {
  withr::local_envvar(ctx_api_key = "local-policy-key")
  statuses <- integer()
  local_mocked_bindings(observe_api_responses = function(responses) {
    statuses <<- vapply(responses, httr2::resp_status, integer(1))
  }, .package = "ComptoxR")
  local_mocked_bindings(req_perform = function(req, ...) {
    httr2::response(status_code = 500L,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('{}'))
  }, .package = "httr2")
  expect_error(ct_chemical_list_all(), "HTTP 500")
  expect_identical(statuses, 500L)
})
