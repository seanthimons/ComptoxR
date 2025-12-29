test_that("generic_chemi_request construction is correct", {
  Sys.setenv(run_debug = "TRUE")
  on.exit(Sys.setenv(run_debug = "FALSE"))
  
  # Test the nested chemicals/options structure
  output <- capture_output(
    dry_run <- generic_chemi_request(
      query = "DTXSID7020182",
      endpoint = "toxprints/calculate",
      options = list(standardize = TRUE)
    )
  )
  
  expect_match(output, "POST")
  expect_match(output, "toxprints/calculate")
  expect_match(output, "\"chemicals\"")
  expect_match(output, "\"sid\"\\s*:\\s*\"DTXSID7020182\"")
  expect_match(output, "\"options\"\\s*:\\s*\\{\\s*\"standardize\"\\s*:\\s*true\\s*\\}")
})

test_that("generic_chemi_request handles unnested payload when wrap=FALSE", {
  Sys.setenv(run_debug = "TRUE")
  on.exit(Sys.setenv(run_debug = "FALSE"))
  
  output <- capture_output(
    dry_run <- generic_chemi_request(
      query = "DTXSID7020182",
      endpoint = "no_wrap",
      wrap = FALSE
    )
  )
  
  # Should be an array of objects directly: [{"sid": "..."}]
  expect_match(output, "\\[\\s*\\{\\s*\"sid\"\\s*:\\s*\"DTXSID7020182\"\\s*\\}\\s*\\]")
})

test_that("generic_chemi_request tidies results with matching query IDs", {
  # Mock a typical chemi response which might be an unnamed list of same length as query
  test_data <- list(
    list(dtxsid = "ID1", val = 10),
    list(dtxsid = "ID2", val = 20)
  )
  
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
      res <- generic_chemi_request(c("ID1", "ID2"), "endpoint")
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 2)
      expect_true("dtxsid" %in% colnames(res))
    }
  )
})
