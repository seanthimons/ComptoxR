test_that("stub generation routes helper-formal query names through query_params", {
  dev_stub_generation <- testthat::test_path("..", "..", "dev", "endpoint_eval", "07_stub_generation.R")
  testthat::skip_if_not(
    file.exists(dev_stub_generation),
    "Maintainer-only test requires dev/endpoint_eval/; dev/ is excluded from CRAN source tarballs"
  )
  source_pipeline_files()

  spec <- tibble::tibble(
    fn = "ct_collision",
    file = "ct_collision.R",
    route = "bioactivity/assay/search/by-endpoint/",
    summary = "Get AEID by assay component endpoint name",
    method = "GET",
    batch_limit = 0L,
    path_params = "",
    query_params = "endpoint",
    body_params = "",
    num_path_params = 0L,
    num_body_params = 0L,
    path_param_metadata = list(list()),
    query_param_metadata = list(list(endpoint = list(required = TRUE))),
    body_param_metadata = list(list()),
    content_type = "application/json",
    request_type = "query_only"
  )

  generated <- render_endpoint_stubs(spec, config = get_stubgen_config())
  text <- generated$text[[1]]

  expect_match(text, 'endpoint = "bioactivity/assay/search/by-endpoint/"', fixed = TRUE)
  expect_match(text, "query_params = list", fixed = TRUE)
  expect_match(text, "`endpoint` = endpoint", fixed = TRUE)
  expect_false(grepl("batch_limit = 0,\n    `endpoint` = endpoint", text, fixed = TRUE))
})

test_that("stub generation sends object POST bodies through explicit body payloads", {
  dev_stub_generation <- testthat::test_path("..", "..", "dev", "endpoint_eval", "07_stub_generation.R")
  testthat::skip_if_not(
    file.exists(dev_stub_generation),
    "Maintainer-only test requires dev/endpoint_eval/; dev/ is excluded from CRAN source tarballs"
  )
  source_pipeline_files()

  spec <- tibble::tibble(
    fn = "ct_object_body",
    file = "ct_object_body.R",
    route = "chemical/msready/search/by-mass/",
    summary = "Get MS-ready chemicals for a batch of mass ranges",
    method = "POST",
    batch_limit = NA_integer_,
    path_params = "",
    query_params = "",
    body_params = "masses,error",
    num_path_params = 0L,
    num_body_params = 2L,
    path_param_metadata = list(list()),
    query_param_metadata = list(list()),
    body_param_metadata = list(list(masses = list(required = TRUE), error = list(required = TRUE))),
    body_schema_full = list(list(
      type = "object",
      properties = list(
        masses = list(type = "array"),
        error = list(type = "number")
      )
    )),
    content_type = "application/json",
    body_schema_type = "simple_object",
    request_type = "json"
  )

  generated <- render_endpoint_stubs(spec, config = get_stubgen_config())
  text <- generated$text[[1]]

  expect_match(text, "request_body <- list()", fixed = TRUE)
  expect_match(text, "request_body$masses <- masses", fixed = TRUE)
  expect_match(text, "body = request_body", fixed = TRUE)
  expect_false(grepl("body = body", text, fixed = TRUE))
})

test_that("stub generation emits the WebTEST flat array request override", {
  dev_stub_generation <- testthat::test_path("..", "..", "dev", "endpoint_eval", "07_stub_generation.R")
  testthat::skip_if_not(
    file.exists(dev_stub_generation),
    "Maintainer-only test requires dev/endpoint_eval/; dev/ is excluded from CRAN source tarballs"
  )
  source_pipeline_files()

  spec <- tibble::tibble(
    fn = "chemi_webtest_predict_bulk",
    file = "chemi_webtest_predict.R",
    route = "webtest/predict",
    summary = "Webtest Predict",
    method = "POST",
    batch_limit = 0L,
    path_params = "",
    query_params = "",
    body_params = "endpoints,structures,format,methods",
    num_path_params = 0L,
    num_body_params = 4L,
    path_param_metadata = list(list()),
    query_param_metadata = list(list()),
    body_param_metadata = list(list(
      endpoints = list(required = TRUE),
      structures = list(required = TRUE),
      format = list(required = FALSE, default = "JSON"),
      methods = list(required = FALSE)
    )),
    body_schema_full = list(list(
      type = "object",
      properties = list(
        endpoints = list(type = "array"),
        structures = list(type = "array"),
        format = list(type = "string"),
        methods = list(type = "array")
      )
    )),
    content_type = "application/json",
    body_schema_type = "simple_object",
    request_type = "json"
  )
  config <- list(
    wrapper_function = "generic_chemi_request",
    param_strategy = "options",
    example_query = "DTXSID7020182",
    lifecycle_badge = "experimental"
  )

  generated <- render_endpoint_stubs(spec, config = config)
  text <- generated$text[[1]]

  expect_match(
    text,
    "function(structures, endpoints, methods = NULL, format = \"JSON\")",
    fixed = TRUE
  )
  expect_match(
    text,
    'run_hook("chemi_webtest_predict_bulk", "pre_request"',
    fixed = TRUE
  )
  expect_match(text, "query = structures", fixed = TRUE)
  expect_match(text, 'sid_label = "structures"', fixed = TRUE)
  expect_match(text, "array_payload = TRUE", fixed = TRUE)
  expect_match(text, "endpoints = endpoints", fixed = TRUE)
  expect_match(text, "methods = methods", fixed = TRUE)
  expect_match(text, "format = format", fixed = TRUE)
  expect_match(
    text,
    'run_hook("chemi_webtest_predict_bulk", "post_response"',
    fixed = TRUE
  )
  expect_false(grepl('"transform"', text, fixed = TRUE))
})

test_that("schema preprocessing excludes WebTEST report and export routes", {
  dev_stub_generation <- testthat::test_path("..", "..", "dev", "endpoint_eval", "07_stub_generation.R")
  testthat::skip_if_not(
    file.exists(dev_stub_generation),
    "Maintainer-only test requires dev/endpoint_eval/; dev/ is excluded from CRAN source tarballs"
  )
  source_pipeline_files()

  schema_file <- tempfile(fileext = ".json")
  jsonlite::write_json(
    list(
      openapi = "3.0.1",
      paths = list(
        "/api/webtest/predict" = list(get = list()),
        "/api/webtest/report" = list(get = list()),
        "/api/webtest/export-append" = list(post = list()),
        "/api/webtest/predict/export" = list(post = list())
      )
    ),
    schema_file,
    auto_unbox = TRUE
  )

  preprocessed <- preprocess_schema(schema_file)

  expect_identical(
    names(preprocessed$paths),
    "/api/webtest/predict"
  )
})
