# Edge-case coverage for generic_request() and generic_chemi_request()
# (issue #231). These complement the happy-path/pagination cases already in
# test-generic_request.R and test-generic_chemi_request.R — assertions here are
# derived from the CURRENT behavior of R/z_generic_request.R.

# --- HTTP status errors: documented graceful behavior (warn + empty) ---

test_that("generic_request warns and returns empty tibble on 4xx (single request)", {
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      httr2::response(
        status_code = 404,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"error":"not found"}')
      )
    },
    .package = "httr2",
    {
      expect_warning(
        res <- generic_request("X", "endpoint", method = "POST"),
        "failed for .* with status 404"
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 0)
    }
  )
})

test_that("generic_request warns on 5xx and drops the failed record when tidy=FALSE", {
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      httr2::response(
        status_code = 503,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"error":"unavailable"}')
      )
    },
    .package = "httr2",
    {
      expect_warning(
        res <- generic_request("X", "endpoint", method = "POST", tidy = FALSE),
        "status 503"
      )
      # A single failing request maps to NULL and survives list_flatten as
      # list(NULL) (the empty-result warning path is only hit at length 0).
      expect_type(res, "list")
      expect_true(all(vapply(res, is.null, logical(1))))
    }
  )
})

test_that("generic_request drops failed batches but keeps successful ones (on_error='continue')", {
  # batch_limit=1 with two items forces req_perform_sequential (>1 batch).
  # One batch succeeds, one returns 500 -> keep the good record, warn on the bad.
  withr::local_envvar(batch_limit = "1")
  testthat::with_mocked_bindings(
    req_perform_sequential = function(reqs, ...) {
      lapply(seq_along(reqs), function(i) {
        if (i == 1) {
          httr2::response(
            status_code = 200,
            headers = list(`Content-Type` = "application/json"),
            body = charToRaw(jsonlite::toJSON(list(list(id = 1)), auto_unbox = TRUE))
          )
        } else {
          httr2::response(
            status_code = 500,
            headers = list(`Content-Type` = "application/json"),
            body = charToRaw('{"error":"server"}')
          )
        }
      })
    },
    .package = "httr2",
    {
      expect_warning(
        res <- generic_request(c("A", "B"), "endpoint", method = "POST", batch_limit = 1),
        "status 500"
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 1)
    }
  )
})

# --- Malformed / non-JSON body: NOT gracefully handled (throws) ---

test_that("generic_request errors on malformed JSON body (200 status)", {
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw("this is not json")
      )
    },
    .package = "httr2",
    {
      # resp_body_json() inside the response map raises a lexical/parse error.
      expect_error(
        generic_request("X", "endpoint", method = "POST"),
        "lexical error|json"
      )
    }
  )
})

# --- Empty payloads / empty result sets ---

test_that("generic_request tidy toggle: empty JSON array -> empty tibble vs empty list", {
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw("[]")
      )
    },
    .package = "httr2",
    {
      expect_warning(
        tib <- generic_request("X", "endpoint", method = "POST", tidy = TRUE),
        "No results found"
      )
      expect_s3_class(tib, "tbl_df")
      expect_equal(nrow(tib), 0)

      expect_warning(
        lst <- generic_request("X", "endpoint", method = "POST", tidy = FALSE),
        "No results found"
      )
      expect_type(lst, "list")
      expect_length(lst, 0)
    }
  )
})

# --- Batching boundaries ---

test_that("generic_request batch_limit=0 sends a static GET and tidies the result", {
  captured_method <- NULL
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      captured_method <<- req$method
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(list(a = 1, b = "x")), auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      res <- generic_request(NULL, "static/endpoint", method = "GET", batch_limit = 0)
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 1)
      expect_equal(captured_method, "GET")
    }
  )
})

test_that("generic_request batch_limit=1 appends the query to the URL path (path-GET)", {
  captured_url <- NULL
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      captured_url <<- req$url
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(list(a = 1)), auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      generic_request("DTXSID123", "assay", method = "GET", batch_limit = 1)
    }
  )
  expect_match(captured_url, "assay/DTXSID123$")
})

test_that("generic_request batch_limit>1 sends a bulk POST JSON array", {
  captured_body <- NULL
  captured_method <- NULL
  withr::local_envvar(ctx_api_key = "k")
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      # httr2 serializes JSON lazily, so req$body$data is the raw payload value.
      captured_body <<- req$body$data
      captured_method <<- req$method
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(list(a = 1)), auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      generic_request(c("A", "B"), "hazard", method = "POST", batch_limit = 200)
    }
  )
  # Both items fit in one batch and become the JSON-array request body.
  expect_equal(captured_method, "POST")
  expect_equal(captured_body, c("A", "B"))
})

# --- path_params + batching abort (downstream wrappers rely on this guard) ---

test_that("generic_request aborts when path_params combined with batch_limit>1", {
  expect_error(
    generic_request(
      c("A", "B"),
      "endpoint",
      method = "GET",
      batch_limit = 200,
      path_params = c("x")
    ),
    "Cannot use path_params with batching",
    class = "rlang_error"
  )
})

# --- Input validation aborts ---

test_that("generic_request aborts on empty query for non-static endpoints", {
  expect_error(
    generic_request(character(0), "endpoint"),
    "Query must be a character vector",
    class = "rlang_error"
  )
})

test_that("generic_request aborts when body is supplied for a non-POST request", {
  expect_error(
    generic_request(query = NULL, endpoint = "endpoint", method = "GET", body = list(x = 1)),
    "can only be supplied for POST",
    class = "rlang_error"
  )
})

test_that("generic_request aborts on unnamed query_params", {
  expect_error(
    generic_request("A", "endpoint", query_params = list(1, 2)),
    "must be a named list",
    class = "rlang_error"
  )
})

# --- generic_chemi_request edges: aborts on non-2xx (unlike generic_request) ---

test_that("generic_chemi_request aborts on 5xx status", {
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      httr2::response(
        status_code = 500,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"error":"boom"}')
      )
    },
    .package = "httr2",
    {
      expect_error(
        generic_chemi_request("ID1", "endpoint"),
        "failed with status 500",
        class = "rlang_error"
      )
    }
  )
})

test_that("generic_chemi_request empty body returns empty tibble vs empty list by tidy", {
  mock_empty <- function(req, ...) {
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw("[]")
    )
  }
  testthat::with_mocked_bindings(
    req_perform = mock_empty,
    .package = "httr2",
    {
      tib <- generic_chemi_request("ID1", "endpoint", tidy = TRUE)
      expect_s3_class(tib, "tbl_df")
      expect_equal(nrow(tib), 0)

      lst <- generic_chemi_request("ID1", "endpoint", tidy = FALSE)
      expect_type(lst, "list")
      expect_length(lst, 0)
    }
  )
})

test_that("generic_chemi_request aborts on empty query with no chemicals", {
  expect_error(
    generic_chemi_request(query = character(0), endpoint = "endpoint"),
    "Either query or chemicals",
    class = "rlang_error"
  )
})
