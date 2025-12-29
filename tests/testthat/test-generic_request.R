test_that("generic_request dry run works independently of network", {
  # Enable debug mode to avoid real requests
  Sys.setenv(run_debug = "TRUE")
  on.exit(Sys.setenv(run_debug = "FALSE"))
  
  # Test POST request construction
  output <- capture_output(
    dry_run <- generic_request(
      query = "DTXSID7020182",
      endpoint = "hazard",
      method = "POST"
    )
  )
  
  expect_match(output, "POST /hazard")
  expect_match(output, "x-api-key:")
  # Match JSON payload with potential whitespace
  expect_match(output, "\\[\\s*\"DTXSID7020182\"\\s*\\]")
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
