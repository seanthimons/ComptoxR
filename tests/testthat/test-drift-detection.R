test_that("extract_function_params correctly extracts formals from known R file", {
  # Source drift detection module
  source(here::here("dev/endpoint_eval/08_drift_detection.R"))

  # Use an existing function in the R/ directory for testing
  # ct_hazard is a known stable function
  test_file <- here::here("R/ct_hazard.R")

  skip_if_not(file.exists(test_file), "Test file R/ct_hazard.R not found")

  # Extract parameters
  params <- extract_function_params(test_file, "ct_hazard")

  # Test: Should return a character vector
  expect_type(params, "character")

  # Test: Should have at least one parameter (query)
  expect_true(length(params) > 0)

  # Test: First parameter should be 'query' (standard for ct_* functions)
  expect_true("query" %in% params)
})

test_that("FRAMEWORK_PARAMS are excluded from drift results", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/04_openapi_parser.R"))
  source(here::here("dev/endpoint_eval/08_drift_detection.R"))

  # Create mock endpoints tibble (schema truth)
  endpoints <- tibble::tibble(
    route = "test/endpoint",
    method = "GET",
    path_params = "query",
    query_params = "",
    body_params = "",
    path_param_metadata = list(NULL),
    query_param_metadata = list(NULL),
    body_param_metadata = list(NULL)
  )

  # Create mock usage summary (function has extra framework param "tidy")
  usage_summary <- tibble::tibble(
    endpoint = "test/endpoint",
    n_hits = 1,
    first_file = "test_function.R"
  )

  # Create temporary test file with framework parameters
  temp_file <- tempfile(fileext = ".R")
  writeLines(c(
    "test_function <- function(query, tidy = TRUE, verbose = FALSE) {",
    "  # Function body",
    "  return(NULL)",
    "}"
  ), temp_file)

  # Mock extract_function_params to return our test params
  original_extract <- extract_function_params
  assign("extract_function_params", function(file_path, function_name) {
    if (basename(file_path) == basename(temp_file)) {
      return(c("query", "tidy", "verbose"))
    }
    original_extract(file_path, function_name)
  }, envir = .GlobalEnv)

  # Mock file.exists to accept our temp file
  pkg_dir_mock <- dirname(temp_file)
  usage_summary$first_file <- basename(temp_file)

  # Detect drift
  drift <- detect_parameter_drift(
    endpoints = endpoints,
    usage_summary = usage_summary,
    pkg_dir = pkg_dir_mock
  )

  # Clean up
  unlink(temp_file)
  rm(extract_function_params, envir = .GlobalEnv)

  # Test: tidy and verbose should NOT appear in drift results
  expect_false("tidy" %in% drift$param_name)
  expect_false("verbose" %in% drift$param_name)

  # Test: Should have 0 drifts since framework params are excluded
  expect_equal(nrow(drift), 0)
})

test_that("param_added drift is detected when schema has new parameter", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/04_openapi_parser.R"))
  source(here::here("dev/endpoint_eval/08_drift_detection.R"))

  # Create mock endpoints tibble with NEW parameter "foo"
  endpoints <- tibble::tibble(
    route = "test/endpoint",
    method = "GET",
    path_params = "query, foo",
    query_params = "",
    body_params = "",
    path_param_metadata = list(list(
      query = list(type = "string"),
      foo = list(type = "string")
    )),
    query_param_metadata = list(NULL),
    body_param_metadata = list(NULL)
  )

  # Create mock usage summary
  usage_summary <- tibble::tibble(
    endpoint = "test/endpoint",
    n_hits = 1,
    first_file = "test_function.R"
  )

  # Create temporary test file WITHOUT "foo" parameter
  temp_file <- tempfile(fileext = ".R")
  writeLines(c(
    "test_function <- function(query) {",
    "  # Function body",
    "  return(NULL)",
    "}"
  ), temp_file)

  # Mock extract_function_params
  original_extract <- extract_function_params
  assign("extract_function_params", function(file_path, function_name) {
    if (basename(file_path) == basename(temp_file)) {
      return(c("query"))
    }
    original_extract(file_path, function_name)
  }, envir = .GlobalEnv)

  pkg_dir_mock <- dirname(temp_file)
  usage_summary$first_file <- basename(temp_file)

  # Detect drift
  drift <- detect_parameter_drift(
    endpoints = endpoints,
    usage_summary = usage_summary,
    pkg_dir = pkg_dir_mock
  )

  # Clean up
  unlink(temp_file)
  rm(extract_function_params, envir = .GlobalEnv)

  # Test: Should detect one param_added drift for "foo"
  expect_equal(nrow(drift), 1)
  expect_equal(drift$drift_type[1], "param_added")
  expect_equal(drift$param_name[1], "foo")
  expect_true(grepl("type:", drift$schema_value[1]))
})

test_that("param_removed drift is detected when function has extra parameter", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/04_openapi_parser.R"))
  source(here::here("dev/endpoint_eval/08_drift_detection.R"))

  # Create mock endpoints tibble WITHOUT "bar" parameter
  endpoints <- tibble::tibble(
    route = "test/endpoint",
    method = "GET",
    path_params = "query",
    query_params = "",
    body_params = "",
    path_param_metadata = list(list(
      query = list(type = "string")
    )),
    query_param_metadata = list(NULL),
    body_param_metadata = list(NULL)
  )

  # Create mock usage summary
  usage_summary <- tibble::tibble(
    endpoint = "test/endpoint",
    n_hits = 1,
    first_file = "test_function.R"
  )

  # Create temporary test file WITH extra "bar" parameter
  temp_file <- tempfile(fileext = ".R")
  writeLines(c(
    "test_function <- function(query, bar = NULL) {",
    "  # Function body",
    "  return(NULL)",
    "}"
  ), temp_file)

  # Mock extract_function_params
  original_extract <- extract_function_params
  assign("extract_function_params", function(file_path, function_name) {
    if (basename(file_path) == basename(temp_file)) {
      return(c("query", "bar"))
    }
    original_extract(file_path, function_name)
  }, envir = .GlobalEnv)

  pkg_dir_mock <- dirname(temp_file)
  usage_summary$first_file <- basename(temp_file)

  # Detect drift
  drift <- detect_parameter_drift(
    endpoints = endpoints,
    usage_summary = usage_summary,
    pkg_dir = pkg_dir_mock
  )

  # Clean up
  unlink(temp_file)
  rm(extract_function_params, envir = .GlobalEnv)

  # Test: Should detect one param_removed drift for "bar"
  expect_equal(nrow(drift), 1)
  expect_equal(drift$drift_type[1], "param_removed")
  expect_equal(drift$param_name[1], "bar")
  expect_equal(drift$code_value[1], "present in function")
})

test_that("drift report is a tibble with expected columns", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/04_openapi_parser.R"))
  source(here::here("dev/endpoint_eval/08_drift_detection.R"))

  # Create mock endpoints tibble
  endpoints <- tibble::tibble(
    route = "test/endpoint",
    method = "GET",
    path_params = "query",
    query_params = "",
    body_params = "",
    path_param_metadata = list(NULL),
    query_param_metadata = list(NULL),
    body_param_metadata = list(NULL)
  )

  # Create mock usage summary with NO hits (no implementation)
  usage_summary <- tibble::tibble(
    endpoint = "test/endpoint",
    n_hits = 0,
    first_file = NA_character_
  )

  # Detect drift
  drift <- detect_parameter_drift(
    endpoints = endpoints,
    usage_summary = usage_summary,
    pkg_dir = "R"
  )

  # Test: Should return a tibble
  expect_s3_class(drift, "tbl_df")

  # Test: Should have expected columns
  expected_cols <- c("endpoint", "file", "function_name", "drift_type", "param_name", "schema_value", "code_value")
  expect_true(all(expected_cols %in% names(drift)))

  # Test: Should have 0 rows when no implementations
  expect_equal(nrow(drift), 0)
})
