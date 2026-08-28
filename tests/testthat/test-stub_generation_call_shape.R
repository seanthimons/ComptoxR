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

test_that("object oneOf bodies are normalized and unsupported variants stay unknown", {
  source_pipeline_files()
  request_body <- function(one_of) {
    list(content = list("application/json" = list(schema = list(oneOf = one_of))))
  }
  shared <- list(type = "integer", description = "first definition")
  variants <- list(
    list(
      type = "object",
      required = c("model_id", "smiles"),
      properties = list(model_id = shared, smiles = list(type = "array"))
    ),
    list(
      type = "object",
      required = c("model_id", "chemicals"),
      properties = list(model_id = list(type = "string"), chemicals = list(type = "array"))
    )
  )

  parsed <- extract_body_properties(request_body(variants), list())
  expect_identical(parsed$type, "one_of")
  expect_identical(names(parsed$properties), c("model_id", "smiles", "chemicals"))
  expect_true(parsed$properties$model_id$required)
  expect_false(parsed$properties$smiles$required)
  expect_identical(parsed$properties$model_id$description, "first definition")
  expect_identical(parsed$required_by_variant, list(c("model_id", "smiles"), c("model_id", "chemicals")))

  components <- list(schemas = list(first = variants[[1]]))
  with_ref <- extract_body_properties(
    request_body(list(list("$ref" = "#/components/schemas/first"), variants[[2]])),
    components
  )
  expect_identical(with_ref$type, "one_of")
  expect_identical(
    extract_body_properties(request_body(list(variants[[1]], list(type = "string"))), list())$type,
    "unknown"
  )

  empty <- extract_body_properties(
    list(content = list("application/json" = list(schema = list(type = "object", properties = list())))),
    list()
  )
  expect_identical(empty$type, "object")
  expect_length(empty$properties, 0L)
})

test_that("free-form object bodies are explicitly blocked", {
  source_pipeline_files()
  request_body <- function(schema) {
    list(content = list("application/json" = list(schema = schema)))
  }
  map_schema <- list(
    type = "object",
    additionalProperties = list(type = "array", items = list(type = "string"))
  )

  parsed <- extract_body_properties(request_body(map_schema), list())
  expect_identical(parsed$type, "unsupported_map")
  expect_identical(parsed$additional_properties, map_schema$additionalProperties)

  named <- extract_body_properties(
    request_body(list(
      type = "object",
      properties = list(id = list(type = "string")),
      additionalProperties = TRUE
    )),
    list()
  )
  expect_identical(named$type, "object")
  expect_identical(
    extract_body_properties(
      request_body(list(type = "object", additionalProperties = FALSE)),
      list()
    )$type,
    "unknown"
  )

  blocked <- is_empty_post_endpoint(
    "POST",
    "format",
    "id",
    parsed,
    "unsupported_map"
  )
  expect_true(blocked$skip)
  expect_identical(
    blocked$reason,
    "Unsupported free-form object body (additionalProperties)"
  )
})

test_that("oneOf wrapper sends exactly one body shape through explicit body", {
  source_pipeline_files()
  schema_path <- testthat::test_path("..", "..", "schema", "chemi-predictor_models-staging.json")
  spec <- openapi_to_spec(jsonlite::fromJSON(schema_path, simplifyVector = FALSE))
  spec <- spec[spec$method == "POST", , drop = FALSE]
  spec$route <- "predictor_models/predict"
  spec$fn <- "chemi_predictor_models_predict_bulk"
  spec$file <- "chemi_predictor_models_predict.R"
  spec$batch_limit <- 0L
  text <- render_endpoint_stubs(spec, config = get_stubgen_config())$text[[1]]
  definition <- Filter(
    function(expression) is.call(expression) && identical(expression[[1]], as.name("<-")),
    as.list(parse(text = text))
  )[[1]]
  generated_fn <- eval(definition[[3]])
  calls <- list()
  generic_chemi_request <- function(...) {
    calls[[length(calls) + 1L]] <<- list(...)
    list(ok = TRUE)
  }

  expect_identical(names(formals(generated_fn)), c("model_id", "smiles", "chemicals"))
  expect_identical(formals(generated_fn)$smiles, quote(NULL))
  expect_identical(formals(generated_fn)$chemicals, quote(NULL))
  generated_fn(1065, smiles = c("CC", "CCC"))
  expect_identical(calls[[1]]$body, list(model_id = 1065, smiles = c("CC", "CCC")))
  generated_fn(1065, chemicals = list(list(id = 1, smiles = "CC")))
  expect_identical(
    calls[[2]]$body,
    list(model_id = 1065, chemicals = list(list(id = 1, smiles = "CC")))
  )
  expect_error(generated_fn(1065), "Supply exactly one supported request-body shape")
  expect_error(
    generated_fn(1065, smiles = "CC", chemicals = list()),
    "Supply exactly one supported request-body shape"
  )
})

test_that("stub generation emits the WebTEST request template with complete hook state", {
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
    body_params = "endpoints,structures,format,methods,chemicals",
    num_path_params = 0L,
    num_body_params = 5L,
    path_param_metadata = list(list()),
    query_param_metadata = list(list()),
    body_param_metadata = list(list(
      endpoints = list(required = TRUE),
      structures = list(required = FALSE),
      format = list(required = FALSE, default = "JSON"),
      methods = list(required = FALSE),
      chemicals = list(required = FALSE)
    )),
    body_schema_full = list(list(
      type = "object",
      properties = list(
        endpoints = list(type = "array"),
        structures = list(type = "array"),
        format = list(type = "string"),
        methods = list(type = "array"),
        chemicals = list(type = "array")
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
    'function(structures, endpoints, methods = NULL, format = "JSON", output = c("wide", "raw"))',
    fixed = TRUE
  )
  expect_match(
    text,
    'run_hook("chemi_webtest_predict_bulk", "pre_request"',
    fixed = TRUE
  )
  expect_match(text, "body = req_data$request$body", fixed = TRUE)
  expect_match(text, "post_data <- req_data", fixed = TRUE)
  expect_match(text, "post_data$result <- result", fixed = TRUE)
  expect_match(text, "result <- req_data$result", fixed = TRUE)
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

test_that("schema preprocessing excludes only harvest resolver routes", {
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
      paths = stats::setNames(
        rep(list(list(get = list())), 6),
        paste0(
          "/api/resolver/",
          c(
            "casharvest",
            "universalharvest",
            "universalharvest_cart",
            "getpubchemlist",
            "getsimilaritylist",
            "orderBySimilarity"
          )
        )
      )
    ),
    schema_file,
    auto_unbox = TRUE
  )

  preprocessed <- preprocess_schema(schema_file)

  expect_identical(
    names(preprocessed$paths),
    paste0(
      "/api/resolver/",
      c("getpubchemlist", "getsimilaritylist", "orderBySimilarity")
    )
  )
})

test_that("resolver stubs include hook-configured output parameters", {
  dev_stub_generation <- testthat::test_path("..", "..", "dev", "endpoint_eval", "07_stub_generation.R")
  testthat::skip_if_not(
    file.exists(dev_stub_generation),
    "Maintainer-only test requires dev/endpoint_eval/; dev/ is excluded from CRAN source tarballs"
  )
  source_pipeline_files()

  schema_path <- testthat::test_path("..", "..", "schema", "chemi-resolver-prod.json")
  spec <- suppressWarnings(
    openapi_to_spec(jsonlite::fromJSON(schema_path, simplifyVector = FALSE))
  )
  spec <- spec[spec$route == "/api/resolver/getsimilaritymap", , drop = FALSE]
  spec$route <- "resolver/getsimilaritymap"
  spec$fn <- "chemi_resolver_getsimilaritymap"
  spec$file <- "chemi_resolver_getsimilaritymap.R"
  spec$batch_limit <- 0L
  config <- list(
    wrapper_function = "generic_chemi_request",
    param_strategy = "options",
    example_query = "DTXSID7020182",
    lifecycle_badge = "experimental"
  )

  text <- render_endpoint_stubs(spec, config = config)$text[[1]]
  definition <- Filter(
    function(expression) {
      is.call(expression) &&
        identical(expression[[1]], as.name("<-")) &&
        identical(as.character(expression[[2]]), "chemi_resolver_getsimilaritymap")
    },
    as.list(parse(text = text))
  )[[1]]
  generated_fn <- eval(definition[[3]])

  expect_true(all(c("hclust_method", "format") %in% names(formals(generated_fn))))
  expect_identical(formals(generated_fn)$sort, FALSE)
  expect_match(text, '"post_response"', fixed = TRUE)
})

test_that("real descriptor schemas render all ten generic hook wrappers", {
  dev_stub_generation <- testthat::test_path("..", "..", "dev", "endpoint_eval", "07_stub_generation.R")
  testthat::skip_if_not(
    file.exists(dev_stub_generation),
    "Maintainer-only test requires dev/endpoint_eval/; dev/ is excluded from CRAN source tarballs"
  )
  source_pipeline_files()

  schema_inputs <- list(
    list(file = "chemi-descriptors-prod.json", service = "descriptors"),
    list(file = "chemi-padel-prod.json", service = "padel"),
    list(file = "chemi-rdkit-staging.json", service = "rdkit"),
    list(file = "chemi-mordred-staging.json", service = "mordred"),
    list(file = "chemi-webtest-prod.json", service = "webtest")
  )
  rows <- lapply(schema_inputs, function(input) {
    schema_path <- testthat::test_path("..", "..", "schema", input$file)
    parsed <- openapi_to_spec(jsonlite::fromJSON(schema_path, simplifyVector = FALSE))
    parsed$route <- sub("^/api/", "", parsed$route)
    parsed <- parsed[parsed$route == input$service, , drop = FALSE]
    parsed$fn <- paste0(
      "chemi_",
      input$service,
      ifelse(parsed$method == "POST", "_bulk", "")
    )
    parsed$file <- paste0("chemi_", input$service, ".R")
    parsed$batch_limit <- 0L
    parsed
  })
  spec <- dplyr::bind_rows(rows)
  config <- list(
    wrapper_function = "generic_chemi_request",
    param_strategy = "options",
    example_query = "DTXSID7020182",
    lifecycle_badge = "experimental"
  )

  rendered <- render_endpoint_stubs(spec, config = config)
  text_by_fn <- stats::setNames(rendered$text, rendered$fn)
  expected_formals <- list(
    chemi_descriptors = c("smiles", "type", "headers", "format", "timeout", "output"),
    chemi_descriptors_bulk = c(
      "query",
      "type",
      "chemIdType",
      "headers",
      "format",
      "timeout",
      "output"
    ),
    chemi_padel = c("smiles", "x2d", "x3d", "fp", "headers", "timeout", "output"),
    chemi_padel_bulk = c("query", "x2d", "x3d", "fp", "headers", "timeout", "output"),
    chemi_rdkit = c("smiles", "type", "radius", "bits", "output"),
    chemi_rdkit_bulk = c("chemicals", "options", "type", "radius", "bits", "output"),
    chemi_mordred = c("smiles", "headers", "inchi", "output"),
    chemi_mordred_bulk = c("chemicals", "options", "headers", "inchi", "output"),
    chemi_webtest = c("smiles", "headers", "output"),
    chemi_webtest_bulk = c("query", "chemIdType", "headers", "format", "output")
  )

  expect_setequal(names(text_by_fn), names(expected_formals))
  for (fn_name in names(expected_formals)) {
    expressions <- parse(text = text_by_fn[[fn_name]])
    definition <- Filter(
      function(expression) {
        is.call(expression) &&
          identical(expression[[1]], as.name("<-")) &&
          identical(as.character(expression[[2]]), fn_name)
      },
      as.list(expressions)
    )[[1]]
    generated_fn <- eval(definition[[3]])
    expect_identical(
      names(formals(generated_fn)),
      expected_formals[[fn_name]],
      info = fn_name
    )

    text <- text_by_fn[[fn_name]]
    pre_position <- regexpr('"pre_request"', text, fixed = TRUE)[[1]]
    helper_name <- if (grepl("_bulk$", fn_name)) {
      "generic_chemi_request"
    } else {
      "generic_request"
    }
    helper_position <- regexpr(paste0(helper_name, "("), text, fixed = TRUE)[[1]]
    post_position <- regexpr('"post_response"', text, fixed = TRUE)[[1]]
    expect_true(
      pre_position < helper_position && helper_position < post_position,
      info = fn_name
    )
    expect_false(grepl('"transform"', text, fixed = TRUE), info = fn_name)
    expect_match(text, "req_data$request$endpoint", fixed = TRUE)
    if (grepl("_bulk$", fn_name)) {
      expect_match(text, "body = req_data$request$body", fixed = TRUE)
    } else {
      expect_match(text, "options = req_data$request$options", fixed = TRUE)
    }

    for (param_name in expected_formals[[fn_name]]) {
      doc_matches <- gregexpr(
        paste0("#' @param ", param_name, " "),
        text,
        fixed = TRUE
      )[[1]]
      expect_equal(
        length(doc_matches[doc_matches > 0]),
        1L,
        info = paste(fn_name, param_name)
      )
    }
  }

  expect_identical(
    formals(eval(parse(text = text_by_fn[["chemi_descriptors_bulk"]])[[1]][[3]]))$chemIdType,
    "AnyId"
  )
  expect_identical(
    formals(eval(parse(text = text_by_fn[["chemi_webtest_bulk"]])[[1]][[3]]))$format,
    "JSON"
  )
  expect_identical(
    formals(eval(parse(text = text_by_fn[["chemi_webtest_bulk"]])[[1]][[3]]))$chemIdType,
    "AnyId"
  )

  native_webtest <- spec[spec$fn == "chemi_webtest_bulk", , drop = FALSE]
  native_params <- strsplit(native_webtest$body_params, ",", fixed = TRUE)[[1]]
  if (!"chemIdType" %in% native_params) {
    native_webtest$body_params <- paste0(native_webtest$body_params, ",chemIdType")
    native_webtest$num_body_params <- native_webtest$num_body_params + 1L
    native_metadata <- native_webtest$body_param_metadata[[1]]
    native_metadata$chemIdType <- list(required = FALSE)
    native_webtest$body_param_metadata <- list(native_metadata)
  }
  native_text <- render_endpoint_stubs(native_webtest, config = config)$text[[1]]
  native_fn <- eval(parse(text = native_text)[[1]][[3]])

  expect_identical(formals(native_fn)$chemIdType, "AnyId")
})
