test_that("generic_chemi_request construction is correct", {
  testthat::skip_if_not_installed("httpuv")

  suppressMessages(run_debug(TRUE))
  Sys.setenv(ctx_api_key = "logic_test_key")
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)

  # Test the nested chemicals/options structure
  output <- capture_output(
    dry_run <- generic_chemi_request(
      query = "DTXSID7020182",
      endpoint = "toxprints/calculate",
      options = list(standardize = TRUE),
      auth = TRUE
    )
  )

  expect_match(output, "POST")
  expect_match(output, "toxprints/calculate")
  expect_match(output, "x-api-key: logic_test_key")
  expect_match(output, "\"chemicals\"")
  expect_match(output, "\"sid\"\\s*:\\s*\"DTXSID7020182\"")
  expect_match(output, "\"options\"\\s*:\\s*\\{\\s*\"standardize\"\\s*:\\s*true\\s*\\}")
})

test_that("generic_chemi_request handles unnested payload when wrap=FALSE", {
  testthat::skip_if_not_installed("httpuv")

  suppressMessages(run_debug(TRUE))
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)

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

test_that("generic_chemi_request sends explicit bodies exactly and preserves duplicates", {
  testthat::skip_if_not_installed("httpuv")
  suppressMessages(run_debug(TRUE))
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)
  body <- list(
    chemicals = I(c("CCO", "CCO", "CCC")),
    options = list(headers = TRUE)
  )

  output <- capture_output(
    generic_chemi_request(
      endpoint = "descriptors",
      server = "https://selected.example/api",
      body = body,
      tidy = FALSE
    )
  )

  expect_match(output, "POST /api/descriptors", fixed = TRUE)
  expect_match(
    output,
    '"chemicals":\\s*\\[\\s*"CCO",\\s*"CCO",\\s*"CCC"\\s*\\]'
  )
  expect_match(output, '"options":\\s*\\{\\s*"headers":\\s*true\\s*\\}')
})

test_that("generic_chemi_request parses configured JSON, CSV, and TSV response types", {
  responses <- list(
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"chemicals":[{"smiles":"CCO"}]}')
    ),
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "text/csv"),
      body = charToRaw("smiles,value\nCCO,1")
    ),
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "text/tab-separated-values"),
      body = charToRaw("smiles\tvalue\nCCO\t1")
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
      json <- generic_chemi_request(
        endpoint = "descriptors",
        body = list(chemicals = I("CCO")),
        tidy = FALSE,
        content_type = "application/json"
      )
      csv <- generic_chemi_request(
        endpoint = "descriptors",
        body = list(chemicals = I("CCO")),
        tidy = FALSE,
        content_type = "text/csv"
      )
      tsv <- generic_chemi_request(
        endpoint = "descriptors",
        body = list(chemicals = I("CCO")),
        tidy = FALSE,
        content_type = "text/tab-separated-values"
      )
    }
  )

  expect_identical(json$chemicals[[1]]$smiles, "CCO")
  expect_s3_class(csv, "data.frame")
  expect_identical(csv$smiles, "CCO")
  expect_identical(csv$value, 1L)
  expect_s3_class(tsv, "data.frame")
  expect_identical(tsv$smiles, "CCO")
  expect_identical(tsv$value, 1L)
})

test_that("generic_chemi_request propagates delimited response parsing failures", {
  response <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "text/csv"),
    body = charToRaw("smiles,value\nCCO")
  )

  testthat::with_mocked_bindings(
    req_perform = function(req) response,
    .package = "httr2",
    expect_error(
      generic_chemi_request(
        endpoint = "descriptors",
        body = list(chemicals = I("CCO")),
        tidy = FALSE,
        content_type = "text/csv"
      ),
      "did not have 2 elements"
    )
  )
})

test_that("generic_chemi_request appends named query parameters", {
  captured_url <- NULL
  testthat::with_mocked_bindings(
    req_perform = function(req) {
      captured_url <<- req$url
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(ok = TRUE), auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      generic_chemi_request(
        query = "DTXSID7020182",
        endpoint = "resolver/getsimilaritymap",
        sort = "true",
        tidy = FALSE
      )
    }
  )

  expect_match(captured_url, "resolver/getsimilaritymap\\?sort=true")
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

# --- Chemi Pagination Tests ---

test_that("generic_chemi_request with paginate=TRUE fetches multiple pages (offset/limit body)", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      if (call_count == 1) {
        data <- list(
          totalRecordsCount = 3,
          recordsCount = 2,
          offset = 0,
          limit = 2,
          records = list(
            list(dtxsid = "DTXSID1", name = "Chem1"),
            list(dtxsid = "DTXSID2", name = "Chem2")
          )
        )
      } else if (call_count == 2) {
        data <- list(
          totalRecordsCount = 3,
          recordsCount = 1,
          offset = 2,
          limit = 2,
          records = list(
            list(dtxsid = "DTXSID3", name = "Chem3")
          )
        )
      } else {
        data <- list(totalRecordsCount = 3, recordsCount = 0, offset = 3, limit = 2, records = list())
      }
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      res <- generic_chemi_request(
        query = "EXACT",
        endpoint = "search",
        options = list(offset = 0, limit = 2),
        tidy = TRUE,
        paginate = TRUE,
        pagination_strategy = "offset_limit",
        max_pages = 10
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 3)
      expect_equal(call_count, 2) # 2 pages: offset=0 (2 records) + offset=2 (1 record, total reached)
    }
  )
})

test_that("generic_chemi_request pagination stops on empty records", {
  call_count <- 0
  testthat::with_mocked_bindings(
    req_perform = function(req, ...) {
      call_count <<- call_count + 1
      data <- list(totalRecordsCount = 0, recordsCount = 0, offset = 0, limit = 10, records = list())
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw(jsonlite::toJSON(data, auto_unbox = TRUE))
      )
    },
    .package = "httr2",
    {
      res <- generic_chemi_request(
        query = "EXACT",
        endpoint = "search",
        options = list(offset = 0, limit = 10),
        tidy = TRUE,
        paginate = TRUE,
        pagination_strategy = "offset_limit",
        max_pages = 5
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 0)
    }
  )
})

test_that("generic_chemi_request with paginate=FALSE still works normally", {
  test_data <- list(list(dtxsid = "DTXSID1", value = "test"))
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
      res <- generic_chemi_request(
        query = "DTXSID7020182",
        endpoint = "toxprints/calculate",
        paginate = FALSE
      )
      expect_s3_class(res, "tbl_df")
      expect_equal(nrow(res), 1)
    }
  )
})
