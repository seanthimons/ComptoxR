webtest_prediction_result <- function(
  chemicals = list(webtest_contract_prediction())
) {
  list(
    id = "prediction-id",
    predictionTime = "2026-07-24T12:00:00Z",
    software = "WebTEST",
    softwareVersion = "1.2.3",
    condition = "complete",
    requestMetadata = list(source = "upstream"),
    chemicals = chemicals
  )
}

test_that("WebTEST prediction interfaces retain their public signatures", {
  expect_identical(
    names(formals(chemi_webtest_predict)),
    c("smiles", "endpoint", "method", "format")
  )
  expect_identical(
    names(formals(chemi_webtest_predict_bulk)),
    c("structures", "endpoints", "methods", "format")
  )
  expect_identical(formals(chemi_webtest_predict)$method, "consensus")
  expect_identical(formals(chemi_webtest_predict)$format, "JSON")
  expect_null(formals(chemi_webtest_predict_bulk)$methods)
  expect_identical(formals(chemi_webtest_predict_bulk)$format, "JSON")
})

test_that("scalar WebTEST prediction resolves identifiers and sends exact GET parameters", {
  withr::local_envvar(
    chemi_burl = "https://selected.example/api"
  )
  captured <- NULL
  selected_server <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      expect_identical(ids, "DTXSID7020182")
      expect_identical(idsType, "AnyId")
      expect_false(tidy)
      list(list(
        result = "FOUND",
        chemical = list(canonicalSmiles = "resolved-smiles")
      ))
    },
    generic_request = function(...) {
      captured <<- list(...)
      selected_server <<- Sys.getenv(captured$server)
      list(webtest_prediction_result())
    },
    .package = "ComptoxR"
  )

  result <- chemi_webtest_predict(
    "DTXSID7020182",
    endpoint = "LC50",
    method = "consensus"
  )

  expect_identical(captured$endpoint, "webtest/predict")
  expect_identical(captured$method, "GET")
  expect_identical(captured$batch_limit, 0)
  expect_identical(captured$server, "chemi_burl")
  expect_identical(selected_server, "https://selected.example/api")
  expect_false(captured$auth)
  expect_false(captured$tidy)
  expect_identical(
    captured$options,
    list(
      smiles = "resolved-smiles",
      endpoint = "LC50",
      method = "consensus",
      format = "JSON"
    )
  )
  expect_length(result, 1)
  expect_identical(result[[1]]$id, "prediction-id")
})

test_that("bulk WebTEST prediction emits the exact flat array payload inputs", {
  captured <- NULL
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured <<- list(...)
      webtest_prediction_result()
    },
    .package = "ComptoxR"
  )

  chemi_webtest_predict_bulk(
    structures = c("CCO", "CCC"),
    endpoints = c("LC50", "LD50"),
    methods = c("consensus", "hc")
  )

  payload <- c(
    stats::setNames(list(as.character(captured$query)), captured$sid_label),
    captured$options
  )
  expect_identical(
    payload,
    list(
      structures = c("CCO", "CCC"),
      endpoints = c("LC50", "LD50"),
      methods = c("consensus", "hc"),
      format = "JSON"
    )
  )
  expect_identical(captured$endpoint, "webtest/predict")
  expect_identical(captured$sid_label, "structures")
  expect_true(captured$array_payload)
  expect_false(captured$tidy)
})

test_that("bulk methods NULL remains a top-level field and does not filter methods", {
  captured <- NULL
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured <<- list(...)
      webtest_prediction_result()
    },
    .package = "ComptoxR"
  )

  result <- chemi_webtest_predict_bulk(
    structures = "CCO",
    endpoints = "LC50"
  )

  expect_true("methods" %in% names(captured$options))
  expect_null(captured$options$methods)
  expect_identical(
    vapply(
      result$chemicals[[1]]$endpoints[[1]]$predicted,
      `[[`,
      character(1),
      "method"
    ),
    c("consensus", "hc")
  )
})

test_that("unresolved WebTEST identifiers are omitted with one warning", {
  captured <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      list(
        list(
          result = "FOUND",
          chemical = list(canonicalSmiles = "resolved-smiles")
        ),
        list(result = "NOT_FOUND")
      )
    },
    generic_chemi_request = function(...) {
      captured <<- list(...)
      webtest_prediction_result()
    },
    .package = "ComptoxR"
  )

  warnings <- character()
  result <- withCallingHandlers(
    chemi_webtest_predict_bulk(
      structures = c("DTXSID7020182", "CCO", "DTXSIDBAD"),
      endpoints = "LC50"
    ),
    warning = function(warning) {
      warnings <<- c(warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )

  expect_length(warnings, 1)
  expect_match(warnings, "DTXSIDBAD", fixed = TRUE)
  expect_identical(captured$query, c("resolved-smiles", "CCO"))
  expect_identical(result$id, "prediction-id")
})

test_that("all-unresolved WebTEST inputs short-circuit the request", {
  called <- FALSE
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      lapply(ids, function(id) list(result = "NOT_FOUND"))
    },
    generic_chemi_request = function(...) {
      called <<- TRUE
      stop("must not be called")
    },
    .package = "ComptoxR"
  )

  expect_warning(
    result <- chemi_webtest_predict_bulk(
      structures = c("DTXSIDBAD", "DTXCIDBAD"),
      endpoints = "LC50"
    ),
    "DTXSIDBAD, DTXCIDBAD",
    fixed = TRUE
  )

  expect_identical(result, list())
  expect_false(called)
})

test_that("prediction filtering preserves metadata, nesting, and embedded errors", {
  embedded_error <- list(
    chemicalId = "unavailable",
    error = list(code = "NO_MODEL", message = "No prediction available")
  )
  upstream <- webtest_prediction_result(
    chemicals = list(webtest_contract_prediction(), embedded_error)
  )
  local_mocked_bindings(
    generic_chemi_request = function(...) upstream,
    .package = "ComptoxR"
  )

  result <- chemi_webtest_predict_bulk(
    structures = "CCO",
    endpoints = "lc50",
    methods = "CONSENSUS"
  )

  expect_identical(result$id, upstream$id)
  expect_identical(result$predictionTime, upstream$predictionTime)
  expect_identical(result$software, upstream$software)
  expect_identical(result$softwareVersion, upstream$softwareVersion)
  expect_identical(result$condition, upstream$condition)
  expect_identical(result$requestMetadata, upstream$requestMetadata)
  expect_identical(result$chemicals[[2]], embedded_error)
  expect_length(result$chemicals[[1]]$endpoints, 1)
  expect_identical(
    result$chemicals[[1]]$endpoints[[1]]$endpoint$id,
    "LC50"
  )
  expect_length(result$chemicals[[1]]$endpoints[[1]]$predicted, 1)
  expect_identical(
    result$chemicals[[1]]$endpoints[[1]]$predicted[[1]]$method,
    "consensus"
  )
})

test_that("WebTEST request validation throws identifiable pre-request conditions", {
  called <- FALSE
  local_mocked_bindings(
    generic_request = function(...) {
      called <<- TRUE
      stop("must not be called")
    },
    .package = "ComptoxR"
  )

  cases <- list(
    endpoint = function() chemi_webtest_predict("CCO"),
    scalar_endpoint = function() {
      chemi_webtest_predict("CCO", endpoint = c("LC50", "LD50"))
    },
    method = function() {
      chemi_webtest_predict("CCO", endpoint = "LC50", method = "unknown")
    },
    format = function() {
      chemi_webtest_predict("CCO", endpoint = "LC50", format = "HTML")
    }
  )

  for (case in cases) {
    condition <- rlang::catch_cnd(case())
    expect_s3_class(
      condition,
      "comptoxr_webtest_pre_request_error"
    )
    expect_s3_class(condition, "comptoxr_webtest_error")
    expect_identical(condition$function_name, "chemi_webtest_predict")
    expect_identical(
      condition$hook_name,
      "validate_webtest_prediction_request"
    )
  }
  expect_false(called)
})

test_that("generic request failures propagate without WebTEST conversion", {
  local_mocked_bindings(
    generic_request = function(...) {
      rlang::abort("transport failure", class = "sentinel_http_error")
    },
    .package = "ComptoxR"
  )

  condition <- rlang::catch_cnd(
    chemi_webtest_predict("CCO", endpoint = "LC50")
  )

  expect_s3_class(condition, "sentinel_http_error")
  expect_false(inherits(condition, "comptoxr_webtest_error"))
})

test_that("malformed responses throw post-response conditions with parents", {
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      list(id = "malformed", chemicals = "not-a-list")
    },
    .package = "ComptoxR"
  )

  condition <- rlang::catch_cnd(
    chemi_webtest_predict_bulk(
      structures = "CCO",
      endpoints = "LC50"
    )
  )

  expect_s3_class(
    condition,
    "comptoxr_webtest_post_response_error"
  )
  expect_s3_class(condition, "comptoxr_webtest_error")
  expect_identical(
    condition$function_name,
    "chemi_webtest_predict_bulk"
  )
  expect_identical(
    condition$hook_name,
    "filter_webtest_prediction_result"
  )
  expect_s3_class(condition$parent, "error")
  expect_match(
    conditionMessage(condition$parent),
    "chemicals must be a list",
    fixed = TRUE
  )
})
