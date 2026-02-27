test_that("build_function_stub generates valid R syntax for chemi endpoint with string-default options", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/07_stub_generation.R"))

  # Simulate body_param_info for chemi endpoint with default value (the "RF" case from BUILD-01)
  body_param_info <- list(
    fn_signature = 'chemicals, model = "RF"',
    param_docs = '#\' @param chemicals Required parameter\n#\' @param model Optional parameter. Options: RF, NN (default: RF)\n',
    has_params = TRUE,
    primary_param = "chemicals"
  )

  path_param_info <- list(
    fn_signature = "",
    path_params_call = "",
    has_path_params = FALSE,
    param_docs = "",
    primary_param = NULL,
    primary_example = NA,
    has_any_path_params = FALSE
  )

  query_param_info <- list(
    fn_signature = "",
    param_docs = "",
    params_code = "",
    params_call = "",
    has_params = FALSE,
    primary_param = NULL,
    primary_example = NA
  )

  config <- list(
    wrapper_function = "generic_chemi_request",
    param_strategy = "options",
    example_query = "DTXSID7020182",
    lifecycle_badge = "experimental"
  )

  # Generate stub
  result <- build_function_stub(
    fn = "chemi_test_function",
    endpoint = "test_endpoint",
    method = "POST",
    title = "Test Function",
    batch_limit = 0,
    path_param_info = path_param_info,
    query_param_info = query_param_info,
    body_param_info = body_param_info,
    content_type = "application/json",
    config = config,
    needs_resolver = FALSE,
    body_schema_type = "object",
    deprecated = FALSE,
    response_schema_type = "object",
    request_type = "json"
  )

  # Test 1: Result should be parseable R code
  expect_no_error(parse(text = result))

  # Test 2: Should not contain invalid syntax like 'model = "RF" <- model = "RF"'
  expect_false(grepl('model = "RF" <- model = "RF"', result, fixed = TRUE))

  # Test 3: Should have proper options assignment: 'if (!is.null(model)) options$model <- model'
  expect_true(grepl("if \\(!is.null\\(model\\)\\) options\\$model <- model", result))

  # Test 4: Should not have default value in the NULL check
  expect_false(grepl('if \\(!is.null\\(model = "RF"\\)\\)', result))
})

test_that("build_function_stub generates valid R syntax for CT endpoint with path params", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/07_stub_generation.R"))

  # Simulate CT endpoint with path parameters
  path_param_info <- list(
    fn_signature = "propertyName, start = NULL, end = NULL",
    path_params_call = ",\n    path_params = c(start = start, end = end)",
    has_path_params = TRUE,
    param_docs = "#' @param propertyName Property name to search for\n#' @param start Start value\n#' @param end End value\n",
    primary_param = "propertyName",
    primary_example = "MolWeight",
    has_any_path_params = TRUE
  )

  query_param_info <- list(
    fn_signature = "",
    param_docs = "",
    params_code = "",
    params_call = "",
    has_params = FALSE,
    primary_param = NULL,
    primary_example = NA
  )

  body_param_info <- list(
    fn_signature = "",
    param_docs = "",
    has_params = FALSE,
    primary_param = NULL
  )

  config <- list(
    wrapper_function = "generic_request",
    param_strategy = "extra_params",
    example_query = "DTXSID7020182",
    lifecycle_badge = "experimental"
  )

  # Generate stub
  result <- build_function_stub(
    fn = "ct_test_function",
    endpoint = "test_endpoint",
    method = "GET",
    title = "Test CT Function",
    batch_limit = 1,
    path_param_info = path_param_info,
    query_param_info = query_param_info,
    body_param_info = body_param_info,
    content_type = "application/json",
    config = config,
    needs_resolver = FALSE,
    body_schema_type = "unknown",
    deprecated = FALSE,
    response_schema_type = "object",
    request_type = "path"
  )

  # Test 1: Result should be parseable R code
  expect_no_error(parse(text = result))

  # Test 2: Should have path_params call
  expect_true(grepl("path_params = c\\(start = start, end = end\\)", result))

  # Test 3: Should have proper function signature
  expect_true(grepl("function\\(propertyName, start = NULL, end = NULL\\)", result))
})

test_that("generated roxygen @param tags match function formal names", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/07_stub_generation.R"))

  # Create a simple endpoint
  path_param_info <- list(
    fn_signature = "query",
    path_params_call = "",
    has_path_params = FALSE,
    param_docs = "#' @param query Primary query parameter\n",
    primary_param = "query",
    primary_example = "DTXSID7020182",
    has_any_path_params = TRUE
  )

  query_param_info <- list(
    fn_signature = "",
    param_docs = "",
    params_code = "",
    params_call = "",
    has_params = FALSE,
    primary_param = NULL,
    primary_example = NA
  )

  body_param_info <- list(
    fn_signature = "",
    param_docs = "",
    has_params = FALSE,
    primary_param = NULL
  )

  config <- list(
    wrapper_function = "generic_request",
    param_strategy = "extra_params",
    example_query = "DTXSID7020182",
    lifecycle_badge = "experimental"
  )

  # Generate stub
  result <- build_function_stub(
    fn = "test_param_match",
    endpoint = "test",
    method = "GET",
    title = "Test Parameter Match",
    batch_limit = 1,
    path_param_info = path_param_info,
    query_param_info = query_param_info,
    body_param_info = body_param_info,
    content_type = "application/json",
    config = config,
    needs_resolver = FALSE,
    body_schema_type = "unknown",
    deprecated = FALSE,
    response_schema_type = "object",
    request_type = "path"
  )

  # Parse the generated code
  parsed <- parse(text = result)

  # Extract function definition
  fn_expr <- NULL
  for (i in seq_along(parsed)) {
    expr <- parsed[[i]]
    if (is.call(expr) && as.character(expr[[1]]) == "<-" &&
        is.call(expr[[3]]) && as.character(expr[[3]][[1]]) == "function") {
      fn_expr <- expr[[3]]
      break
    }
  }

  expect_false(is.null(fn_expr))

  # Extract formals
  actual_formals <- names(formals(eval(fn_expr)))

  # Extract @param names from roxygen
  lines <- strsplit(result, "\n")[[1]]
  param_lines <- grep("^#' @param ", lines, value = TRUE)
  documented_params <- sub("^#' @param (\\S+).*", "\\1", param_lines)

  # Test: All formals should be documented
  expect_setequal(documented_params, actual_formals)

  # Test: No extra documentation for non-existent parameters
  expect_true(all(documented_params %in% actual_formals))
})

test_that("generated code handles reserved word defaults correctly", {
  # Source dependencies
  source(here::here("dev/endpoint_eval/00_config.R"))
  source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
  source(here::here("dev/endpoint_eval/06_param_parsing.R"))
  source(here::here("dev/endpoint_eval/07_stub_generation.R"))

  # Test with boolean defaults
  body_param_info <- list(
    fn_signature = "query, verbose = TRUE, check = FALSE",
    param_docs = "#' @param query Query parameter\n#' @param verbose Verbose output\n#' @param check Check results\n",
    has_params = TRUE,
    primary_param = "query"
  )

  path_param_info <- list(
    fn_signature = "",
    path_params_call = "",
    has_path_params = FALSE,
    param_docs = "",
    primary_param = NULL,
    primary_example = NA,
    has_any_path_params = FALSE
  )

  query_param_info <- list(
    fn_signature = "",
    param_docs = "",
    params_code = "",
    params_call = "",
    has_params = FALSE,
    primary_param = NULL,
    primary_example = NA
  )

  config <- list(
    wrapper_function = "generic_chemi_request",
    param_strategy = "options",
    example_query = "DTXSID7020182",
    lifecycle_badge = "experimental"
  )

  # Generate stub
  result <- build_function_stub(
    fn = "test_reserved_words",
    endpoint = "test",
    method = "POST",
    title = "Test Reserved Words",
    batch_limit = 0,
    path_param_info = path_param_info,
    query_param_info = query_param_info,
    body_param_info = body_param_info,
    content_type = "application/json",
    config = config,
    needs_resolver = FALSE,
    body_schema_type = "object",
    deprecated = FALSE,
    response_schema_type = "object",
    request_type = "json"
  )

  # Test: Should parse without error
  expect_no_error(parse(text = result))

  # Test: Should have correct boolean checks (not "TRUE" in strings)
  expect_true(grepl("if \\(!is.null\\(verbose\\)\\) options\\$verbose <- verbose", result))
  expect_true(grepl("if \\(!is.null\\(check\\)\\) options\\$check <- check", result))

  # Test: Should NOT have malformed syntax like 'verbose = TRUE <- verbose = TRUE'
  expect_false(grepl("verbose = TRUE <- verbose = TRUE", result, fixed = TRUE))
  expect_false(grepl("check = FALSE <- check = FALSE", result, fixed = TRUE))
})
