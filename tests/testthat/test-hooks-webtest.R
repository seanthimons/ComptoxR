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

test_that("WebTEST prediction interfaces retain generated public contracts", {
  expect_identical(
    names(formals(chemi_webtest_predict)),
    c("smiles", "endpoint", "method", "format", "output")
  )
  expect_identical(
    names(formals(chemi_webtest_predict_bulk)),
    c("structures", "endpoints", "methods", "format", "output")
  )
  expect_identical(formals(chemi_webtest_predict)$method, "consensus")
  expect_identical(formals(chemi_webtest_predict)$format, "JSON")
  expect_identical(formals(chemi_webtest_predict)$output, quote(c("wide", "raw")))
  expect_null(formals(chemi_webtest_predict_bulk)$methods)
  expect_identical(formals(chemi_webtest_predict_bulk)$format, "JSON")
  expect_identical(formals(chemi_webtest_predict_bulk)$output, quote(c("wide", "raw")))

  source <- paste(readLines(testthat::test_path("..", "..", "R", "chemi_webtest_predict.R")), collapse = "\n")
  for (fn_name in c("chemi_webtest_predict", "chemi_webtest_predict_bulk")) {
    definition <- parse(text = source)
    definition <- Filter(
      function(expression) {
        is.call(expression) &&
          identical(expression[[1]], as.name("<-")) &&
          identical(as.character(expression[[2]]), fn_name)
      },
      as.list(definition)
    )[[1]]
    body_text <- paste(deparse(definition[[3]][[3]], width.cutoff = 500L), collapse = "\n")
    expect_true(
      regexpr('"pre_request"', body_text, fixed = TRUE)[[1]] < regexpr("generic_", body_text, fixed = TRUE)[[1]],
      info = fn_name
    )
    expect_true(
      regexpr("generic_", body_text, fixed = TRUE)[[1]] < regexpr('"post_response"', body_text, fixed = TRUE)[[1]],
      info = fn_name
    )
    expect_match(body_text, "post_data <- req_data", fixed = TRUE, info = fn_name)
  }
})

test_that("scalar prediction sends exact GET state and returns wide rows", {
  withr::local_envvar(chemi_burl = "https://selected.example/api")
  captured <- NULL
  upstream <- webtest_prediction_result()
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      expect_identical(ids, "DTXSID7020182")
      expect_identical(idsType, "AnyId")
      expect_false(tidy)
      list(list(
        result = "FOUND",
        chemical = list(
          sid = "DTXSID7020182",
          canonicalSmiles = "resolved-smiles"
        )
      ))
    },
    generic_request = function(...) {
      captured <<- list(...)
      list(upstream)
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
  expect_identical(captured$server, "https://selected.example/api")
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
  expect_identical(result$query, "DTXSID7020182")
  expect_identical(result$input_index, 1L)
  expect_identical(result$status, "ok")
  expect_identical(result$endpoint_id, "LC50")
  expect_identical(result$method, "consensus")
  expect_equal(result$value, 3.241)
  expect_equal(result$log_value, 4.848)
  expect_identical(result$source_server, "https://selected.example/api")
  expect_identical(result$source_endpoint, "webtest/predict")
})

test_that("bulk prediction sends the exact flat JSON body", {
  captured <- NULL
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured <<- list(...)
      webtest_prediction_result(
        chemicals = list(
          webtest_contract_prediction(smiles = "CCO"),
          webtest_contract_prediction(smiles = "CCC")
        )
      )
    },
    .package = "ComptoxR"
  )

  chemi_webtest_predict_bulk(
    structures = c("CCO", "CCC"),
    endpoints = c("LC50", "LD50"),
    methods = c("consensus", "hc")
  )

  expect_identical(captured$endpoint, "webtest/predict")
  expect_identical(captured$server, chemi_server(1, url_only = TRUE))
  expect_false(captured$auth)
  expect_false(captured$tidy)
  expect_identical(as.character(captured$body$structures), c("CCO", "CCC"))
  expect_identical(as.character(captured$body$endpoints), c("LC50", "LD50"))
  expect_identical(as.character(captured$body$methods), c("consensus", "hc"))
  expect_identical(captured$body$format, "JSON")
})

test_that("wide prediction preserves duplicates and emits one row per failure", {
  embedded_error <- list(
    chemicalId = "bad[",
    error = list(code = "INVALID", message = "invalid structure")
  )
  no_prediction <- webtest_contract_prediction(chemical_id = "CCC", smiles = "CCC")
  no_prediction$endpoints <- no_prediction$endpoints[2]
  upstream <- webtest_prediction_result(
    chemicals = list(
      webtest_contract_prediction(chemical_id = "CCO", smiles = "CCO"),
      embedded_error,
      no_prediction
    )
  )
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      list(list(result = "NOT_FOUND"))
    },
    generic_chemi_request = function(...) upstream,
    .package = "ComptoxR"
  )

  expect_warning(
    result <- chemi_webtest_predict_bulk(
      structures = c("CCO", "CCO", "DTXSIDBAD", "bad[", "CCC"),
      endpoints = "LC50",
      methods = c("consensus", "hc")
    ),
    "DTXSIDBAD",
    fixed = TRUE
  )

  expect_identical(result$query, c("CCO", "CCO", "CCO", "CCO", "DTXSIDBAD", "bad[", "CCC"))
  expect_identical(result$input_index, c(1L, 1L, 2L, 2L, 3L, 4L, 5L))
  expect_identical(result$status, c("ok", "ok", "ok", "ok", "error", "error", "error"))
  expect_identical(result$method[1:4], rep(c("consensus", "hc"), 2))
  expect_match(result$error[[5]], "Unable to resolve")
  expect_match(result$error[[6]], "INVALID: invalid structure")
  expect_match(result$error[[7]], "No requested WebTEST prediction")
})

test_that("all-invalid prediction skips HTTP and still formats error rows", {
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
      c("DTXSIDBAD", "DTXCIDBAD"),
      endpoints = "LC50"
    ),
    "DTXSIDBAD, DTXCIDBAD",
    fixed = TRUE
  )

  expect_false(called)
  expect_identical(result$query, c("DTXSIDBAD", "DTXCIDBAD"))
  expect_identical(result$input_index, 1:2)
  expect_true(all(result$status == "error"))
  expect_true(all(result$source_endpoint == "webtest/predict"))
})

test_that("raw prediction preserves the unfiltered PredictionResult", {
  upstream <- webtest_prediction_result()
  local_mocked_bindings(
    generic_chemi_request = function(...) upstream,
    .package = "ComptoxR"
  )

  result <- chemi_webtest_predict_bulk(
    structures = "CCO",
    endpoints = "LC50",
    methods = "consensus",
    output = "raw"
  )

  payload <- result
  attr(payload, "source_server") <- NULL
  attr(payload, "source_endpoint") <- NULL
  attr(payload, "input_map") <- NULL
  expect_identical(payload, upstream)
  expect_length(result$chemicals[[1]]$endpoints, 2)
  expect_length(result$chemicals[[1]]$endpoints[[1]]$predicted, 2)
  expect_identical(attr(result, "source_endpoint"), "webtest/predict")
  expect_length(attr(result, "input_map"), 1)
})

test_that("bulk methods NULL retains every returned method in wide output", {
  local_mocked_bindings(
    generic_chemi_request = function(...) webtest_prediction_result(),
    .package = "ComptoxR"
  )

  result <- chemi_webtest_predict_bulk("CCO", endpoints = "LC50")

  expect_identical(result$method, c("consensus", "hc"))
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
    },
    output = function() {
      chemi_webtest_predict("CCO", endpoint = "LC50", output = "nested")
    }
  )

  for (case in cases) {
    condition <- rlang::catch_cnd(case())
    expect_s3_class(condition, "comptoxr_webtest_pre_request_error")
    expect_s3_class(condition, "comptoxr_webtest_error")
    expect_identical(condition$function_name, "chemi_webtest_predict")
    expect_identical(condition$hook_name, "validate_webtest_prediction_request")
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
    chemi_webtest_predict_bulk("CCO", endpoints = "LC50")
  )

  expect_s3_class(condition, "comptoxr_webtest_post_response_error")
  expect_s3_class(condition, "comptoxr_webtest_error")
  expect_identical(condition$function_name, "chemi_webtest_predict_bulk")
  expect_identical(condition$hook_name, "filter_webtest_prediction_result")
  expect_s3_class(condition$parent, "error")
  expect_match(conditionMessage(condition$parent), "chemicals must be a list", fixed = TRUE)
})
