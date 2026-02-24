test_that("generic_request dry run works independently of network", {
  # Enable debug mode to avoid real requests
  Sys.setenv(run_debug = "TRUE")
  Sys.setenv(ctx_api_key = "logic_test_key")
  on.exit({
    Sys.setenv(run_debug = "FALSE")
    # Restore dummy key if needed, though setup.R handles it usually
  })
  
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
  Sys.setenv(run_debug = "TRUE")
  on.exit(Sys.setenv(run_debug = "FALSE"))
  
  # Custom server via literal URL
  output_custom <- capture_output(generic_request("A", "endpoint", server = "http://test.com/api"))
  expect_match(output_custom, "POST /api/endpoint")
})

test_that("generic_request handles batching logic correctly", {
  Sys.setenv(run_debug = "TRUE")
  Sys.setenv(batch_limit = "2")
  on.exit({
    Sys.setenv(run_debug = "FALSE")
    Sys.setenv(batch_limit = "100")
  })
  
  output <- capture_output(
    dry_run <- generic_request(
      query = c("A", "B", "C", "D", "E"),
      endpoint = "test",
      method = "POST"
    )
  )
  
  expect_match(output, "\\[\\s*\"A\",\\s*\"B\"\\s*\\]")
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
      res <- generic_request("DTXSID7020182", "hazard", method = "POST",
                             paginate = FALSE, pagination_strategy = "page_number")
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
      expect_true(call_count >= 3)  # At least 3 calls (2 with data + 1 empty)
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
      res <- generic_request(
        query = "DEV",
        endpoint = "hazard/toxref/search/by-study-type/",
        method = "GET",
        batch_limit = 1,
        paginate = TRUE,
        pagination_strategy = "page_number",
        max_pages = 3,
        pageNumber = 1
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

test_that("generic_cc_request with paginate=TRUE fetches multiple pages", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      if (call_count == 1) {
        # Page 1: return full page (size=1, 1 result = full page)
        data <- list(
          count = "3",
          results = list(list(rn = "50-01-0", name = "Chem1"))
        )
      } else if (call_count == 2) {
        # Page 2: return full page
        data <- list(
          count = "3",
          results = list(list(rn = "50-02-0", name = "Chem2"))
        )
      } else {
        # Page 3: empty results signals end
        data <- list(count = "3", results = list())
      }
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      Sys.setenv(cc_api_key = "test_cc_key")
      res <- generic_cc_request(
        endpoint = "search",
        method = "GET",
        paginate = TRUE,
        pagination_strategy = "offset_limit",
        max_pages = 10,
        q = "formaldehyde",
        offset = 0,
        size = 1
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 2)
      expect_true(call_count >= 3)
    }
  )
})
