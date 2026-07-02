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
