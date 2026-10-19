probe_json_response <- function(req, status = 200L, url = req$url, body = '[{"ok":true}]') {
  httr2::response(
    status_code = status,
    url = url,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(body)
  )
}

# Exercise native failures while public vector wrappers await Specmill #135.
probe_native_wrapper <- function(internal_id) {
  .ct_request_each(function(chunk) {
    .ct_request(
      method = "GET", path = "/api/amos/get_info_by_id/{internal_id}",
      path_params = list(internal_id = chunk), query = list(), body = NULL,
      response_policy = ".ct_list",
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl")
    )
  }, internal_id, 1L, on_error = "drop")
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

  result <- probe_api_function("CHEMI_AMOS_GET_INFO_BY_ID", internal_id = "group-42")

  expect_identical(result$environment, "configured")
  expect_identical(result$server_id, 1L)
  expect_true(all(result$valid))
  expect_true(all(grepl("group-42", request_urls, fixed = TRUE)))
  expect_identical(Sys.getenv("chemi_burl"), "https://original.example/api")
  expect_identical(.ComptoxREnv$probe_observer, sentinel)
})

test_that("probe uses the approved CompTox default", {
  testthat::local_mocked_bindings(
    req_perform = function(req) probe_json_response(req),
    .package = "httr2"
  )

  result <- probe_api_function(
    "ct_chemical_count_by_exact_formula",
    formula = "H2O",
    projection = "count"
  )

  expect_identical(result$server_id, 1L)
  expect_identical(
    result$environment,
    "production"
  )
  expect_true(all(result$valid))
  expect_true(all(vapply(result$status_codes, identical, logical(1), 200L)))
})

test_that("probe reports empty, non-200, redirected, and thrown results", {
  testthat::local_mocked_bindings(chemi_amos_get_info_by_id = probe_native_wrapper,
    .package = "ComptoxR")
  cases <- list(
    list(body = '[]', message = 'Result is empty'),
    list(status = 503L, message = 'HTTP status was not 200'),
    list(url = 'https://redirect.example/api/amos/get_info_by_id/group-42', message = 'Observed URL does not match')
  )
  for (case in cases) {
    testthat::local_mocked_bindings(
      req_perform = function(req) {
        args <- case[setdiff(names(case), 'message')]
        do.call(probe_json_response, c(list(req = req), args))
      },
      .package = 'httr2'
    )
    result <- suppressWarnings(probe_api_function('chemi_amos_get_info_by_id', internal_id = 'group-42'))
    expect_false(any(result$valid))
    expect_match(result$error[[1]], case$message, fixed = TRUE)
  }
  testthat::local_mocked_bindings(req_perform = function(req) stop('request exploded'), .package = 'httr2')
  expect_warning(errors <- probe_api_function('chemi_amos_get_info_by_id', internal_id = 'group-42'), "failed")
  expect_false(any(errors$valid))
  expect_match(errors$error[[1]], "HTTP request failed before a response was received", fixed = TRUE)
  expect_identical(errors$error[[1]], unname(attr(errors$result[[1]], "failed")[[1]]))
  testthat::local_mocked_bindings(chemi_amos_get_info_by_id = function(...) stop("request exploded"),
    .package = "ComptoxR")
  errors <- probe_api_function('chemi_amos_get_info_by_id', internal_id = 'group-42')
  expect_true(all(errors$error == 'request exploded'))
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
  # Paging sends one request per page through httr2::req_perform().
  pages <- c(
    '{"totalRecordsCount":2,"recordsCount":1,"offset":0,"records":[{"id":1}]}',
    '{"totalRecordsCount":2,"recordsCount":1,"offset":1,"records":[{"id":2}]}'
  )
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      page <- pages[[1]]
      pages <<- pages[-1]
      probe_json_response(req, body = page)
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


test_that("probe rejects partial native batches with unobserved request failures", {
  testthat::local_mocked_bindings(chemi_amos_get_info_by_id = probe_native_wrapper,
    .package = "ComptoxR")
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    if (endsWith(req$url, "/group-2")) stop("request exploded")
    probe_json_response(req)
  }, .package = "httr2")
  expect_warning(result <- probe_api_function("chemi_amos_get_info_by_id", internal_id = c("group-1", "group-2")), "failed")
  expect_false(any(result$valid))
  expect_identical(result$status_codes[[1]], 200L)
  expect_match(result$error[[1]], "HTTP request failed before a response was received", fixed = TRUE)
})
