probe_json_response <- function(req, status = 200L, url = req$url, body = '[{"ok":true}]') {
  httr2::response(
    status_code = status,
    url = url,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(body)
  )
}

test_that("probe resolves Chemi wrappers case-insensitively and forwards arguments", {
  withr::local_envvar(chemi_burl = "https://original.example/api")
  had_observer <- exists("probe_observer", envir = .ComptoxREnv, inherits = FALSE)
  old_observer <- if (had_observer) .ComptoxREnv$probe_observer else NULL
  on.exit(
    {
      if (had_observer) {
        .ComptoxREnv$probe_observer <- old_observer
      } else if (exists("probe_observer", envir = .ComptoxREnv, inherits = FALSE)) {
        rm("probe_observer", envir = .ComptoxREnv)
      }
    },
    add = TRUE
  )
  sentinel <- function(response) NULL
  .ComptoxREnv$probe_observer <- sentinel
  request_urls <- character()

  testthat::local_mocked_bindings(
    req_perform = function(req) {
      request_urls <<- c(request_urls, req$url)
      probe_json_response(req)
    },
    .package = "httr2"
  )

  result <- probe_api_function("CHEMI_ALERTS_GROUPS_BY_ID", id = "group-42")

  expect_identical(result$environment, c("production", "staging", "development"))
  expect_identical(result$server_id, 1:3)
  expect_true(all(result$valid))
  expect_true(all(grepl("group-42", request_urls, fixed = TRUE)))
  expect_identical(Sys.getenv("chemi_burl"), "https://original.example/api")
  expect_identical(.ComptoxREnv$probe_observer, sentinel)
})

test_that("probe enumerates all recognized CompTox servers", {
  testthat::local_mocked_bindings(
    req_perform = function(req) probe_json_response(req),
    .package = "httr2"
  )

  result <- probe_api_function(
    "ct_chemical_count_by_exact_formula",
    formula = "H2O",
    projection = "count"
  )

  expect_identical(result$server_id, c(1L, 2L, 3L, 5L))
  expect_identical(
    result$environment,
    c("production", "staging", "development", "legacy staging")
  )
  expect_true(all(result$valid))
  expect_true(all(vapply(result$status_codes, identical, logical(1), 200L)))
})

test_that("probe reports empty, non-200, redirected, and thrown results", {
  testthat::local_mocked_bindings(
    req_perform = function(req) {
      if (grepl("hcd.rtpnc", req$url, fixed = TRUE)) {
        return(probe_json_response(req, body = "[]"))
      }
      if (grepl("cim.sciencedataexperts", req$url, fixed = TRUE)) {
        return(probe_json_response(req, status = 503L))
      }
      probe_json_response(req, url = "https://redirect.example/api/alerts/groups/group-42")
    },
    .package = "httr2"
  )

  result <- suppressWarnings(probe_api_function("chemi_alerts_groups_by_id", id = "group-42"))

  expect_false(any(result$valid))
  expect_match(result$error[[1]], "Result is empty", fixed = TRUE)
  expect_match(result$error[[2]], "HTTP status was not 200", fixed = TRUE)
  expect_match(result$error[[3]], "Observed URL does not match", fixed = TRUE)

  testthat::local_mocked_bindings(
    req_perform = function(req) stop("request exploded"),
    .package = "httr2"
  )
  errors <- probe_api_function("chemi_alerts_groups_by_id", id = "group-42")
  expect_true(all(errors$error == "request exploded"))
})

test_that("probe reports wrappers whose HTTP status cannot be observed", {
  legacy_wrapper <- function(...) {
    observe_api_responses(list(
      httr2::response(
        status_code = 200L,
        url = paste0(Sys.getenv("chemi_burl"), "/nested-helper")
      )
    ))
    tibble::tibble(ok = TRUE)
  }
  testthat::local_mocked_bindings(
    chemi_functional_use = legacy_wrapper,
    chemi_predict = legacy_wrapper,
    chemi_safety_section = legacy_wrapper,
    .package = "ComptoxR"
  )

  results <- lapply(
    c("chemi_functional_use", "chemi_predict", "chemi_safety_section"),
    probe_api_function,
    query = "DTXSID7020182"
  )

  for (result in results) {
    expect_false(any(result$valid))
    expect_true(all(result$error == "HTTP status not observable."))
    expect_true(all(lengths(result$status_codes) == 0L))
  }
})

test_that("probe rejects unsupported and non-wrapper names", {
  expect_error(probe_api_function("generic_request"), "must name an exported")
  expect_error(probe_api_function("chemi_not_real"), "No exported ComptoxR function")
  expect_error(probe_api_function("chemi_server"), "not an API wrapper")
  expect_error(probe_api_function("ct_api_key"), "not an API wrapper")
  expect_error(probe_api_function(character()), "one non-empty function name")
})

test_that("response observer sees batched and paginated helper responses", {
  statuses <- integer()
  had_observer <- exists("probe_observer", envir = .ComptoxREnv, inherits = FALSE)
  old_observer <- if (had_observer) .ComptoxREnv$probe_observer else NULL
  on.exit(
    {
      if (had_observer) {
        .ComptoxREnv$probe_observer <- old_observer
      } else if (exists("probe_observer", envir = .ComptoxREnv, inherits = FALSE)) {
        rm("probe_observer", envir = .ComptoxREnv)
      }
    },
    add = TRUE
  )
  .ComptoxREnv$probe_observer <- function(response) {
    statuses <<- c(statuses, httr2::resp_status(response))
  }

  testthat::local_mocked_bindings(
    req_perform_sequential = function(reqs, ...) {
      lapply(reqs, probe_json_response)
    },
    .package = "httr2"
  )
  generic_request(c("A", "B"), "endpoint", method = "POST", batch_limit = 1)
  expect_identical(statuses, c(200L, 200L))

  statuses <- integer()
  testthat::local_mocked_bindings(
    req_perform_iterative = function(req, ...) {
      list(
        probe_json_response(
          req,
          body = '{"totalRecordsCount":2,"recordsCount":1,"offset":0,"records":[{"id":1}]}'
        ),
        probe_json_response(
          req,
          body = '{"totalRecordsCount":2,"recordsCount":1,"offset":1,"records":[{"id":2}]}'
        )
      )
    },
    .package = "httr2"
  )
  result <- generic_chemi_request(
    query = "EXACT",
    endpoint = "search",
    options = list(limit = 1),
    paginate = TRUE,
    pagination_strategy = "offset_limit"
  )
  expect_identical(statuses, c(200L, 200L))
  expect_equal(nrow(result), 2L)
})
