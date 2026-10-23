if (!exists('generated_contract_ensure_package', mode = 'function')) {
  source(file.path('tests', 'testthat', 'helper-generated-contracts.R'))
}
generated_contract_ensure_package()
prediction_response <- function(body = '{"score":0,"flag":false,"absent":null}', status = 200L) {
  httr2::response(status, headers = list('content-type' = 'application/json'), body = charToRaw(body))
}
classifier_snapshot <- function(expr) tryCatch(list(value = force(expr)), error = function(e) list(error_class = class(e), message = conditionMessage(e)))

test_that('prediction retains resolved payloads, field order, transport policy and no hooks', {
  withr::local_envvar(c(chemi_burl = 'http://127.0.0.1:9999/chemi'))
  resolved <- list(list(sid = 'one', smiles = 'CCO', mol = NULL, flag = FALSE, count = 0))
  captured <- queries <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup = function(query, ...) {queries <<- list(query); resolved},
    req_perform = function(req, ...) {captured <<- req; prediction_response()},
    run_hook = function(...) stop('no hook expected'), .package = 'ComptoxR'
  )
  for (q in list(FALSE, 0, character(), c('one','one'), NA_character_, '')) {
    result <- suppressMessages(chemi_predict(q))
    expect_identical(queries, list(q))
    expect_identical(result, list(score = 0L, flag = FALSE, absent = NULL))
    expect_identical(captured$body$data, list(structures = resolved, report = 'JSON'))
  }
  expect_identical(captured$method, 'POST')
  expect_identical(captured$url, 'http://127.0.0.1:9999/chemi/webtest/predict')
  expect_identical(unclass(captured$headers), list(Accept = 'application/json, text/plain, */*'))
  expect_null(captured$policies$retry)
  expect_true(captured$body$params$auto_unbox)
  resolved <- tibble::tibble(sid = 'one', flag = FALSE, count = 0)
  suppressMessages(chemi_predict('one'))
  expect_identical(captured$body$data$structures, resolved)
})

test_that('prediction preserves validation order, warnings and error paths', {
  resolved <- 'CCO'
  report <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup = function(query, ...) resolved,
    req_perform = function(req, ...) {report <<- req$body$data$report; prediction_response()},
    .package = 'ComptoxR'
  )
  expect_error(chemi_predict(), 'argument "query" is missing', fixed = TRUE)
  expect_error(chemi_predict(NULL, report = stop('report evaluated')), 'Request missing', fixed = TRUE)
  for (r in list('UNKNOWN','unknown',FALSE,0,NA_character_)) {
    expect_warning(suppressMessages(chemi_predict('one', r)), 'Invalid report format')
    expect_identical(report, 'JSON')
  }
  for (r in c('SDF','SMI','MOL','CSV','TSV','JSON','XLSX','PDF','HTML','XML','DOCX')) {
    expect_no_warning(suppressMessages(chemi_predict('one', r)))
    expect_identical(report, r)
  }
  for (r in list(NULL, character())) expect_error(suppressMessages(chemi_predict('one', r)), 'argument is of length zero')
  expect_error(suppressMessages(chemi_predict('one', c('JSON','SDF'))), 'condition has length > 1')
  for (value in list(NULL, character(), list(), tibble::tibble())) {
    resolved <- value
    expect_error(chemi_predict('one', report = stop('report evaluated')), 'No chemicals resolved')
  }
  local_mocked_bindings(chemi_resolver_lookup = function(...) stop('resolver failed'), .package = 'ComptoxR')
  expect_error(chemi_predict('one', report = stop('report evaluated')), 'resolver failed')
})

test_that('prediction propagates transport, HTTP, malformed JSON and empty response behavior', {
  response <- prediction_response()
  local_mocked_bindings(chemi_resolver_lookup = function(...) 'CCO', req_perform = function(...) response, .package = 'ComptoxR')
  for (body in c('null','[]','{}')) {
    response <- prediction_response(body)
    expect_identical(suppressMessages(chemi_predict('one')), httr2::resp_body_json(response))
  }
  response <- prediction_response('not-json')
  expect_error(suppressMessages(chemi_predict('one')))
  for (status in c(400L,500L)) {
    response <- prediction_response('{}',status)
    expect_error(suppressMessages(chemi_predict('one')), paste('API request failed with status',status), fixed = TRUE)
  }
  local_mocked_bindings(req_perform = function(...) stop('transport failed'), .package = 'ComptoxR')
  expect_error(suppressMessages(chemi_predict('one')), 'transport failed')
})

test_that('classifier preserves original single-row and batch classifications and classes', {
  withr::local_options(list(cli.unicode = FALSE, cli.num_colors = 1))
  fixture <- readRDS(test_path('fixtures/specmill-classifier-contract.rds'))
  settings <- get('.ComptoxREnv', asNamespace('ComptoxR'))
  rlang::local_bindings(classifier = NULL, .env = settings)
  local_mocked_bindings(req_perform = function(...) stop('no transport'), run_hook = function(...) stop('no hooks'), .package = 'ComptoxR')
  expect_identical(ct_classify(fixture$input), fixture$batch)
  for (i in seq_len(nrow(fixture$input))) expect_identical(ct_classify(fixture$input[i,]), fixture$rows[[i]])
  expect_identical(ct_classify(as.data.frame(fixture$input)), fixture$dataframe)
  expect_identical(names(fixture$batch), c(names(fixture$input),'class','super_class','composition'))
  expect_identical(fixture$batch$metadata, fixture$input$metadata)
  # Existing isTRUE operates on the whole vector: a row's flags differ in a batch.
  expect_identical(fixture$rows[[4]]$class, 'MARKUSH')
  expect_identical(fixture$batch$class[[4]], 'ORG_FORMULA')
  expect_identical(fixture$rows[[3]]$class, 'ISOTOPE')
  expect_identical(fixture$batch$class[[3]], 'UNKNOWN_FINAL')
  for (name in c('empty','missing_column','null','false','zero')) {
    input <- switch(name, empty = fixture$input[0,], missing_column = dplyr::select(fixture$input,-smiles), null = NULL, false = FALSE, zero = 0)
    expect_identical(classifier_snapshot(ct_classify(input)), fixture[[name]])
  }
  expect_error(ct_classify(), 'argument "df" is missing', fixed = TRUE)
})

test_that('classifier reuses the cached closure and initializes it only when NULL', {
  settings <- get('.ComptoxREnv', asNamespace('ComptoxR'))
  calls <- 0L
  cached <- function(df) invisible(list(df = df))
  rlang::local_bindings(classifier = cached, .env = settings)
  local_mocked_bindings(create_compound_classifier = function() {calls <<- calls + 1L; cached}, .package = 'ComptoxR')
  result <- withVisible(ct_classify(FALSE))
  expect_identical(result, list(value = list(df = FALSE), visible = FALSE))
  expect_identical(calls, 0L)
  settings$classifier <- NULL
  expect_identical(ct_classify(0), list(df = 0))
  expect_identical(ct_classify(NULL), list(df = NULL))
  expect_identical(calls, 1L)
  expect_identical(settings$classifier, cached)
  settings$classifier <- FALSE
  expect_error(ct_classify(0))
  expect_identical(calls, 1L)
})
