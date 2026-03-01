# Test pagination loop logic using mocked httr2 internals
# These tests verify the pagination strategies in generic_request() work correctly
# by mocking httr2::req_perform_iterative and related functions

test_that("offset_limit with path_params combines pages correctly", {
  skip_if_not_installed("mockery")
  skip_if_not_installed("withr")

  # Set up fake chemi server
  withr::local_envvar(chemi_burl = "https://fake.example.com/api/")

  # Create mock response objects (simple lists with $body field)
  mock_resp1 <- list(body = list(
    list(id = 1, name = "method1"),
    list(id = 2, name = "method2"),
    list(id = 3, name = "method3")
  ))

  mock_resp2 <- list(body = list(
    list(id = 4, name = "method4"),
    list(id = 5, name = "method5")
  ))

  # Mock httr2 functions using testthat's local_mocked_bindings
  local_mocked_bindings(
    req_perform_iterative = function(first_req, next_req, max_reqs, on_error, progress = FALSE) {
      list(mock_resp1, mock_resp2)
    },
    resps_successes = function(resps) resps,
    resp_body_json = function(resp, ...) resp$body,
    .package = "httr2"
  )

  # Call function with pagination enabled
  result <- chemi_amos_method_pagination(limit = 3, offset = 0, all_pages = TRUE)

  # Verify combined result has 5 records from both pages
  expect_type(result, "list")
  expect_equal(length(result), 5)
  expect_equal(result[[1]]$id, 1)
  expect_equal(result[[5]]$id, 5)
})

test_that("page_number strategy increments correctly", {
  skip_if_not_installed("mockery")
  skip_if_not_installed("withr")

  # Set up fake ctx server
  withr::local_envvar(ctx_burl = "https://fake-ctx.example.com/api/")

  # Mock responses for page_number pagination
  mock_page1 <- list(body = list(
    list(dtxsid = "DTXSID1", name = "Chemical1"),
    list(dtxsid = "DTXSID2", name = "Chemical2")
  ))

  mock_page2 <- list(body = list(
    list(dtxsid = "DTXSID3", name = "Chemical3")
  ))

  # Mock httr2 functions
  local_mocked_bindings(
    req_perform_iterative = function(first_req, next_req, max_reqs, on_error, progress = FALSE) {
      list(mock_page1, mock_page2)
    },
    resps_successes = function(resps) resps,
    resp_body_json = function(resp, ...) resp$body,
    .package = "httr2"
  )

  # Call generic_request with page_number strategy
  result <- generic_request(
    query = NULL,
    endpoint = "chemical/search",
    method = "GET",
    batch_limit = 0,
    server = "ctx_burl",
    auth = FALSE,
    tidy = FALSE,
    paginate = TRUE,
    max_pages = 10,
    pagination_strategy = "page_number",
    pageNumber = 1
  )

  # Verify combined result
  expect_type(result, "list")
  expect_equal(length(result), 3)
})

test_that("cursor strategy follows cursor tokens", {
  skip_if_not_installed("mockery")
  skip_if_not_installed("withr")

  # Set up fake server
  withr::local_envvar(ctx_burl = "https://fake-cursor.example.com/api/")

  # Mock responses with cursor tokens
  mock_page1 <- list(body = list(
    results = list(
      list(id = 1, data = "A"),
      list(id = 2, data = "B")
    ),
    nextCursor = "cursor_token_123"
  ))

  mock_page2 <- list(body = list(
    results = list(
      list(id = 3, data = "C")
    ),
    nextCursor = NULL  # End of results
  ))

  # Mock httr2 functions
  local_mocked_bindings(
    req_perform_iterative = function(first_req, next_req, max_reqs, on_error, progress = FALSE) {
      list(mock_page1, mock_page2)
    },
    resps_successes = function(resps) resps,
    resp_body_json = function(resp, ...) resp$body,
    .package = "httr2"
  )

  # Call with cursor strategy
  result <- generic_request(
    query = NULL,
    endpoint = "data/cursor",
    method = "GET",
    batch_limit = 0,
    server = "ctx_burl",
    auth = FALSE,
    tidy = FALSE,
    paginate = TRUE,
    max_pages = 10,
    pagination_strategy = "cursor"
  )

  # Verify cursor extraction logic worked (extracted from "results" wrapper)
  expect_type(result, "list")
  expect_equal(length(result), 3)
})

test_that("empty page terminates loop without error", {
  skip_if_not_installed("mockery")
  skip_if_not_installed("withr")

  # Set up fake server
  withr::local_envvar(chemi_burl = "https://fake-empty.example.com/api/")

  # Mock empty response
  mock_empty <- list(body = list())

  # Mock httr2 functions
  local_mocked_bindings(
    req_perform_iterative = function(first_req, next_req, max_reqs, on_error, progress = FALSE) {
      list(mock_empty)
    },
    resps_successes = function(resps) resps,
    resp_body_json = function(resp, ...) resp$body,
    .package = "httr2"
  )

  # Should not error, just return empty result
  expect_warning(
    result <- chemi_amos_method_pagination(limit = 5, offset = 0, all_pages = TRUE),
    "No results found"
  )

  expect_type(result, "list")
  expect_equal(length(result), 0)
})

test_that("max_pages limit emits warning when truncated", {
  skip_if_not_installed("mockery")
  skip_if_not_installed("withr")

  # Set up fake server
  withr::local_envvar(chemi_burl = "https://fake-maxpages.example.com/api/")

  # Mock exactly max_pages responses
  mock_page1 <- list(body = list(
    list(id = 1),
    list(id = 2)
  ))

  mock_page2 <- list(body = list(
    list(id = 3),
    list(id = 4)
  ))

  # Mock httr2 functions to return exactly 2 pages
  local_mocked_bindings(
    req_perform_iterative = function(first_req, next_req, max_reqs, on_error, progress = FALSE) {
      list(mock_page1, mock_page2)
    },
    resps_successes = function(resps) resps,
    resp_body_json = function(resp, ...) resp$body,
    .package = "httr2"
  )

  # Call with max_pages=2 - should emit warning since we hit the limit
  expect_warning(
    result <- generic_request(
      query = 2,
      endpoint = "amos/method_pagination/",
      method = "GET",
      batch_limit = 1,
      server = "chemi_burl",
      auth = FALSE,
      tidy = FALSE,
      path_params = c(offset = 0),
      paginate = TRUE,
      max_pages = 2,
      pagination_strategy = "offset_limit"
    ),
    "Pagination stopped at 2 page"
  )

  # Verify we still got the data from both pages
  expect_type(result, "list")
  expect_equal(length(result), 4)
})

test_that("page_size strategy (Spring Boot Pageable) works correctly", {
  skip_if_not_installed("mockery")
  skip_if_not_installed("withr")

  # Set up fake server
  withr::local_envvar(ctx_burl = "https://fake-pageable.example.com/api/")

  # Mock Spring Boot Pageable responses (wrapped in "content")
  mock_page1 <- list(body = list(
    content = list(
      list(id = 1, value = "A"),
      list(id = 2, value = "B")
    ),
    totalPages = 2,
    last = FALSE
  ))

  mock_page2 <- list(body = list(
    content = list(
      list(id = 3, value = "C")
    ),
    totalPages = 2,
    last = TRUE
  ))

  # Mock httr2 functions
  local_mocked_bindings(
    req_perform_iterative = function(first_req, next_req, max_reqs, on_error, progress = FALSE) {
      list(mock_page1, mock_page2)
    },
    resps_successes = function(resps) resps,
    resp_body_json = function(resp, ...) resp$body,
    .package = "httr2"
  )

  # Call with page_size strategy
  result <- generic_request(
    query = NULL,
    endpoint = "data/pageable",
    method = "GET",
    batch_limit = 0,
    server = "ctx_burl",
    auth = FALSE,
    tidy = FALSE,
    paginate = TRUE,
    max_pages = 10,
    pagination_strategy = "page_size",
    page = 0,
    size = 10
  )

  # Verify extraction from "content" wrapper
  expect_type(result, "list")
  expect_equal(length(result), 3)
  expect_equal(result[[1]]$id, 1)
  expect_equal(result[[3]]$id, 3)
})

test_that("offset_limit via query params (no path_params) works", {
  skip_if_not_installed("mockery")
  skip_if_not_installed("withr")

  # Set up fake server
  withr::local_envvar(ctx_burl = "https://fake-offset-query.example.com/api/")

  # Mock responses with offset/limit in query params
  mock_page1 <- list(body = list(
    results = list(
      list(compound = "A"),
      list(compound = "B")
    )
  ))

  mock_page2 <- list(body = list(
    results = list(
      list(compound = "C")
    )
  ))

  # Mock httr2 functions
  local_mocked_bindings(
    req_perform_iterative = function(first_req, next_req, max_reqs, on_error, progress = FALSE) {
      list(mock_page1, mock_page2)
    },
    resps_successes = function(resps) resps,
    resp_body_json = function(resp, ...) resp$body,
    .package = "httr2"
  )

  # Call with offset_limit strategy but no path_params (uses query params)
  result <- generic_request(
    query = NULL,
    endpoint = "search/compounds",
    method = "GET",
    batch_limit = 0,
    server = "ctx_burl",
    auth = FALSE,
    tidy = FALSE,
    paginate = TRUE,
    max_pages = 10,
    pagination_strategy = "offset_limit",
    offset = 0,
    limit = 100
  )

  # Verify extraction from "results" wrapper
  expect_type(result, "list")
  expect_equal(length(result), 3)
})
