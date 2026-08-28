if (!exists("epi_schema", mode = "function")) {
  pkgload::load_all(quiet = TRUE)
}

epi_schema_response <- function(req, body, status = 200L) {
  httr2::response(
    status_code = status,
    url = req$url,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(body)
  )
}

read_schema_file <- function(path) {
  readChar(path, nchars = file.info(path)$size, useBytes = TRUE)
}

test_that("epi_schema downloads and validates the production schema", {
  schema_dir <- withr::local_tempdir()
  withr::local_envvar(epi_burl = "epi-sentinel")
  body <- '{"openapi":"3.0.3","info":{"version":"1.0.3-beta"},"paths":{"/api/submit":{"post":{}}}}'
  requested_url <- NULL
  requested_timeout <- NULL

  testthat::local_mocked_bindings(
    req_perform = function(req) {
      requested_url <<- req$url
      requested_timeout <<- req$options$timeout_ms
      epi_schema_response(req, body)
    },
    .package = "httr2"
  )

  result <- epi_schema(timeout = 17, schema_dir = schema_dir)
  schema_file <- file.path(schema_dir, "epi-suite-prod.json")

  expect_null(result)
  expect_identical(requested_url, epi_server(1, url_only = TRUE))
  expect_identical(requested_timeout, 17000)
  expect_true(file.exists(schema_file))
  expect_identical(read_schema_file(schema_file), body)
  expect_identical(Sys.getenv("epi_burl"), "epi-sentinel")
})

test_that("epi_schema preserves an existing file after an HTTP error", {
  schema_dir <- withr::local_tempdir()
  schema_file <- file.path(schema_dir, "epi-suite-prod.json")
  writeLines("existing schema", schema_file, useBytes = TRUE)
  existing <- readBin(schema_file, what = "raw", n = file.info(schema_file)$size)

  testthat::local_mocked_bindings(
    req_perform = function(req) {
      epi_schema_response(req, '{"openapi":"3.0.3","paths":{"/api":{}}}', status = 503L)
    },
    .package = "httr2"
  )

  expect_error(
    epi_schema(schema_dir = schema_dir),
    "EPI Suite schema request failed with HTTP 503",
    fixed = TRUE
  )
  expect_identical(
    readBin(schema_file, what = "raw", n = file.info(schema_file)$size),
    existing
  )
})

test_that("epi_schema preserves an existing file after invalid JSON", {
  schema_dir <- withr::local_tempdir()
  schema_file <- file.path(schema_dir, "epi-suite-prod.json")
  writeLines("existing schema", schema_file, useBytes = TRUE)
  existing <- readBin(schema_file, what = "raw", n = file.info(schema_file)$size)

  testthat::local_mocked_bindings(
    req_perform = function(req) epi_schema_response(req, "{not-json"),
    .package = "httr2"
  )

  expect_error(
    epi_schema(schema_dir = schema_dir),
    "EPI Suite schema is not valid JSON",
    fixed = TRUE
  )
  expect_identical(
    readBin(schema_file, what = "raw", n = file.info(schema_file)$size),
    existing
  )
})

test_that("epi_schema removes invalid control bytes", {
  schema_dir <- withr::local_tempdir()
  body <- paste0(
    '{"openapi":"3.0.3","paths":{"/api":{}},"description":"before\u00d7',
    intToUtf8(23L),
    'after"}'
  )

  testthat::local_mocked_bindings(
    req_perform = function(req) epi_schema_response(req, body),
    .package = "httr2"
  )

  epi_schema(schema_dir = schema_dir)
  schema_file <- file.path(schema_dir, "epi-suite-prod.json")
  expected <- gsub(intToUtf8(23L), "", body, fixed = TRUE)

  expect_identical(
    readBin(schema_file, what = "raw", n = file.info(schema_file)$size),
    charToRaw(expected)
  )
  expect_silent(jsonlite::fromJSON(schema_file))
})

test_that("epi_schema requires OpenAPI 3 and a non-empty paths object", {
  schema_dir <- withr::local_tempdir()
  schema_file <- file.path(schema_dir, "epi-suite-prod.json")
  writeLines("existing schema", schema_file, useBytes = TRUE)
  existing <- readBin(schema_file, what = "raw", n = file.info(schema_file)$size)
  response_body <- NULL

  testthat::local_mocked_bindings(
    req_perform = function(req) epi_schema_response(req, response_body),
    .package = "httr2"
  )

  invalid_schemas <- list(
    missing_openapi = '{"paths":{"/api":{}}}',
    wrong_openapi = '{"openapi":"2.0","paths":{"/api":{}}}',
    missing_paths = '{"openapi":"3.0.3"}',
    empty_paths = '{"openapi":"3.0.3","paths":{}}',
    array_paths = '{"openapi":"3.0.3","paths":[{"path":"/api"}]}'
  )

  for (schema_name in names(invalid_schemas)) {
    response_body <- invalid_schemas[[schema_name]]
    expected_error <- if (schema_name %in% c("missing_openapi", "wrong_openapi")) {
      "EPI Suite schema must be an OpenAPI 3 document"
    } else {
      "EPI Suite schema must have a non-empty paths object"
    }

    expect_error(
      epi_schema(schema_dir = schema_dir),
      expected_error,
      fixed = TRUE,
      info = schema_name
    )
    expect_identical(
      readBin(schema_file, what = "raw", n = file.info(schema_file)$size),
      existing,
      info = schema_name
    )
  }
})
