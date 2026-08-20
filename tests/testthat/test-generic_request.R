test_that("generic_request dry run works independently of network", {
  testthat::skip_if_not_installed("httpuv")

  # Enable debug mode to avoid real requests
  suppressMessages(run_debug(TRUE))
  Sys.setenv(ctx_api_key = "logic_test_key")
  on.exit(
    {
      suppressMessages(run_debug(FALSE))
      # Restore dummy key if needed, though setup.R handles it usually
    },
    add = TRUE
  )

  # Test POST request construction
  output <- capture_output(
    dry_run <- generic_request(
      query = "DTXSID7020182",
      endpoint = "hazard",
      method = "POST"
    )
  )

  expect_match(output, "POST")
  expect_match(output, "hazard")
  expect_match(output, "x-api-key: logic_test_key")
  # Match JSON payload with potential whitespace
  expect_match(output, "\\[\\s*\"DTXSID7020182\"\\s*\\]")
})

test_that("generic_request respects different server environments", {
  testthat::skip_if_not_installed("httpuv")

  suppressMessages(run_debug(TRUE))
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)

  # Custom server via literal URL
  output_custom <- capture_output(generic_request("A", "endpoint", server = "http://test.com/api"))
  expect_match(output_custom, "POST /api/endpoint")
})

test_that("generic_request handles batching logic correctly", {
  testthat::skip_if_not_installed("httpuv")

  suppressMessages(run_debug(TRUE))
  Sys.setenv(batch_limit = "2")
  on.exit(
    {
      suppressMessages(run_debug(FALSE))
      Sys.setenv(batch_limit = "100")
    },
    add = TRUE
  )

  output <- capture_output(
    dry_run <- generic_request(
      query = c("A", "B", "C", "D", "E"),
      endpoint = "test",
      method = "POST"
    )
  )

  expect_match(output, "\\[\\s*\"A\",\\s*\"B\"\\s*\\]")
})

test_that("generic_request progress follows the verbose option", {
  withr::local_envvar(run_debug = "TRUE")
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)
  suppressMessages(run_debug(FALSE))
  progress_values <- logical()
  response <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('[{"id":1}]')
  )

  testthat::with_mocked_bindings(
    req_perform_iterative = function(req, next_req, max_reqs, on_error, progress) {
      progress_values <<- c(progress_values, progress)
      list(response)
    },
    .package = "httr2",
    {
      for (verbose in c(FALSE, TRUE)) {
        suppressMessages(withr::with_options(
          list(ComptoxR.run_verbose = verbose),
          generic_request(
            "A",
            "endpoint",
            method = "GET",
            server = "https://example.test/api",
            batch_limit = 1,
            auth = FALSE,
            paginate = TRUE,
            max_pages = 2,
            pagination_strategy = "page_number",
            pageNumber = 1
          )
        ))
      }
    }
  )

  expect_identical(progress_values, c(FALSE, TRUE))
  expect_identical(Sys.getenv("run_debug"), "TRUE")
})

test_that("generic_request tidies simple results into tibbles", {
  # Let's mock a simple list response
  test_data <- list(list(id = 1, name = "Test1"), list(id = 2, name = "Test2"))

  testthat::with_mocked_bindings(
    req_perform = function(req) {
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(test_data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      res <- generic_request("dummy", "endpoint", method = "POST")
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 2)
      expect_equal(colnames(res), c("id", "name"))
    }
  )
})

test_that("generic_request parses CSV and TSV responses", {
  responses <- list(
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "text/csv"),
      body = charToRaw("smiles,value\nCCO,1")
    ),
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "text/tab-separated-values"),
      body = charToRaw("smiles\tvalue\nCCC\t2")
    )
  )
  call_index <- 0L

  testthat::with_mocked_bindings(
    req_perform = function(req) {
      call_index <<- call_index + 1L
      responses[[call_index]]
    },
    .package = "httr2",
    {
      csv <- generic_request(
        endpoint = "descriptors",
        method = "GET",
        batch_limit = 0,
        content_type = "text/csv"
      )
      tsv <- generic_request(
        endpoint = "descriptors",
        method = "GET",
        batch_limit = 0,
        content_type = "text/tab-separated-values"
      )
    }
  )

  expect_s3_class(csv, "data.frame")
  expect_identical(csv$smiles, "CCO")
  expect_identical(csv$value, 1L)
  expect_s3_class(tsv, "data.frame")
  expect_identical(tsv$smiles, "CCC")
  expect_identical(tsv$value, 2L)
})

test_that("generic_request handles empty results gracefully", {
  testthat::with_mocked_bindings(
    req_perform = function(req) {
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(), auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      # Should return empty tibble when tidy=TRUE (default)
      expect_warning(res <- generic_request("dummy", "endpoint"), "No results found")
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 0)

      # Should return empty list when tidy=FALSE
      expect_warning(res_list <- generic_request("dummy", "endpoint", tidy = FALSE), "No results found")
      expect_type(res_list, "list")
      expect_equal(length(res_list), 0)
    }
  )
})

# --- Pagination Tests ---

test_that("generic_request with paginate=FALSE preserves existing behavior", {
  test_data <- list(list(id = 1, name = "Test1"))
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(test_data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      res <- generic_request(
        "DTXSID7020182",
        "hazard",
        method = "POST",
        paginate = FALSE,
        pagination_strategy = "page_number"
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 1)
    }
  )
})

test_that("generic_request with paginate=TRUE and page_number fetches multiple pages", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      if (call_count <= 2) {
        # Pages 1-2: return records
        data <- list(list(id = call_count, name = paste0("Record", call_count)))
        httr2::response(
          status_code = 200,
          headers = list(`Content-Type` = "application/json"),
          body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
        )
      } else {
        # Page 3: empty response signals end
        httr2::response(
          status_code = 200,
          headers = list(`Content-Type` = "application/json"),
          body = charToRaw("[]")
        )
      }
    },
    .package = "httr2",
    {
      res <- generic_request(
        query = "DEV",
        endpoint = "hazard/toxref/observations/search/by-study-type/",
        method = "GET",
        batch_limit = 1,
        paginate = TRUE,
        pagination_strategy = "page_number",
        max_pages = 10,
        pageNumber = 1
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 2)
      expect_true(call_count >= 3) # At least 3 calls (2 with data + 1 empty)
    }
  )
})

test_that("generic_request with paginate=TRUE and page_size (Spring Boot) stops on last=TRUE", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      data <- list(
        content = list(list(id = call_count, value = paste0("item", call_count))),
        number = call_count - 1,
        totalPages = 2,
        totalElements = 2,
        last = (call_count >= 2),
        first = (call_count == 1),
        size = 1
      )
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      Sys.setenv(ctx_api_key = "test_key")
      res <- generic_request(
        query = "test",
        endpoint = "resolver/classyfire",
        method = "GET",
        batch_limit = 0,
        paginate = TRUE,
        pagination_strategy = "page_size",
        max_pages = 10,
        page = 0,
        size = 1
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 2)
      expect_equal(call_count, 2)
    }
  )
})

test_that("generic_request pagination respects max_pages limit", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      data <- list(list(id = call_count))
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      expect_warning(
        res <- generic_request(
          query = "DEV",
          endpoint = "hazard/toxref/search/by-study-type/",
          method = "GET",
          batch_limit = 1,
          paginate = TRUE,
          pagination_strategy = "page_number",
          max_pages = 3,
          pageNumber = 1
        ),
        "max_pages"
      )
      # Should stop at 3 pages even though responses never empty
      expect_true(call_count <= 3)
    }
  )
})

test_that("generic_request pagination returns empty tibble on no results", {
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
        res <- generic_request(
          query = "NONE",
          endpoint = "hazard/search/",
          method = "GET",
          batch_limit = 1,
          paginate = TRUE,
          pagination_strategy = "page_number",
          max_pages = 5,
          pageNumber = 1
        ),
        "No results found"
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 0)
    }
  )
})

test_that("generic_request pagination with tidy=FALSE returns list", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      if (call_count <= 2) {
        data <- list(list(id = call_count))
        httr2::response(
          status_code = 200,
          headers = list(`Content-Type` = "application/json"),
          body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
        )
      } else {
        httr2::response(
          status_code = 200,
          headers = list(`Content-Type` = "application/json"),
          body = charToRaw("[]")
        )
      }
    },
    .package = "httr2",
    {
      res <- generic_request(
        query = "DEV",
        endpoint = "hazard/search/",
        method = "GET",
        batch_limit = 1,
        tidy = FALSE,
        paginate = TRUE,
        pagination_strategy = "page_number",
        max_pages = 10,
        pageNumber = 1
      )
      expect_type(res, "list")
      expect_equal(length(res), 2)
    }
  )
})

test_that("generic_request with paginate=TRUE and cursor follows cursor tokens", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      if (call_count == 1) {
        data <- list(
          data = list(list(id = 1, name = "First")),
          cursor = "abc123"
        )
      } else if (call_count == 2) {
        data <- list(
          data = list(list(id = 2, name = "Second")),
          cursor = NULL
        )
      } else {
        data <- list(data = list(), cursor = NULL)
      }
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE, null = "null"))
      )
    },
    .package = "httr2",
    {
      res <- generic_request(
        query = "100",
        endpoint = "amos/method_keyset_pagination/",
        method = "GET",
        batch_limit = 1,
        paginate = TRUE,
        pagination_strategy = "cursor",
        max_pages = 10
      )
      # Should get records from 2 pages (cursor NULL on page 2 stops iteration)
      expect_type(res, "list")
    }
  )
})

test_that("generic_request advances nested query cursors and honors hasNext", {
  requests <- list()
  call_count <- 0L
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1L
      requests[[call_count]] <<- req
      data <- if (call_count == 1L) {
        list(
          results = list(list(id = 1)),
          pagination = list(hasNext = TRUE, nextCursor = "next-query")
        )
      } else {
        list(
          results = list(list(id = 2)),
          pagination = list(hasNext = FALSE, nextCursor = "unused")
        )
      }
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      result <- generic_request(
        query = "1",
        endpoint = "amos/method_keyset_pagination/",
        method = "GET",
        server = "https://example.test/api",
        auth = FALSE,
        tidy = FALSE,
        batch_limit = 1,
        cursor = "start",
        filter = "keep",
        paginate = TRUE,
        max_pages = 10,
        pagination_strategy = "cursor",
        pagination_cursor_location = "query"
      )
    }
  )

  expect_equal(call_count, 2L)
  expect_length(result, 2L)
  expect_match(requests[[2]]$url, "cursor=next-query", fixed = TRUE)
  expect_match(requests[[2]]$url, "filter=keep", fixed = TRUE)
})

test_that("generic_request advances body cursors without changing filters or sort", {
  requests <- list()
  call_count <- 0L
  initial_body <- list(
    cursor = "start",
    filters = list(source = list(type = "equals", filter = "EPA")),
    sortModel = list(list(colId = "method_name", sort = "asc"))
  )
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1L
      requests[[call_count]] <<- req
      data <- if (call_count == 1L) {
        list(
          results = list(list(id = 1)),
          pagination = list(hasNext = TRUE, nextCursor = "next-body")
        )
      } else {
        list(results = list(list(id = 2)), pagination = list(hasNext = FALSE))
      }
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      result <- generic_request(
        query = NULL,
        endpoint = "amos/method_keyset_pagination/",
        method = "POST",
        server = "https://example.test/api",
        auth = FALSE,
        tidy = FALSE,
        batch_limit = 0,
        path_params = c(limit = 1),
        body = initial_body,
        paginate = TRUE,
        max_pages = 10,
        pagination_strategy = "cursor",
        pagination_cursor_location = "body"
      )
    }
  )

  expect_equal(call_count, 2L)
  expect_length(result, 2L)
  expect_identical(requests[[2]]$body$data$cursor, "next-body")
  expect_identical(requests[[2]]$body$data$filters, initial_body$filters)
  expect_identical(requests[[2]]$body$data$sortModel, initial_body$sortModel)
})

test_that("generic_request unwraps a single results collection", {
  response_body <- list(results = list(list(id = 1), list(id = 2)))
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(response_body, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      result <- generic_request(
        endpoint = "amos/method_list",
        method = "GET",
        server = "https://example.test/api",
        auth = FALSE,
        tidy = FALSE,
        batch_limit = 0
      )
    }
  )

  expect_length(result, 2L)
  expect_identical(result[[1]]$id, 1L)
})
