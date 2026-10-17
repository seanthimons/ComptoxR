test_that("list-all HTTP failures preserve empty results and post hooks", {
  withr::local_envvar(ctx_api_key = "local-policy-key")
  for (status in c(404L, 500L)) {
    local_mocked_bindings(req_perform = function(req, ...) {
      httr2::response(status_code = status,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"error":"missing"}'))
    }, .package = "httr2")
    for (args in list(list(), list(return_dtxsid = TRUE),
        list(return_dtxsid = TRUE, coerce = TRUE))) {
      warnings <- character()
      value <- withCallingHandlers(suppressMessages(do.call(ct_chemical_list_all, args)),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        })
      if (isTRUE(args$coerce)) {
        expect_identical(value, structure(list(), names = character()))
        expect_length(warnings, 2L)
        expect_match(warnings[[2L]], "listName")
      } else {
        expect_identical(value, tibble::tibble())
        expect_length(warnings, 1L)
      }
      expect_match(warnings[[1L]], paste("status", status))
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
  suppressWarnings(suppressMessages(ct_chemical_list_all()))
  expect_identical(statuses, 500L)
})
