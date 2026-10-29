if (!exists('generated_contract_ensure_package', mode = 'function')) {
  source(file.path('tests', 'testthat', 'helper-generated-contracts.R'))
}
generated_contract_ensure_package()
classifier_snapshot <- function(expr) tryCatch(list(value = force(expr)), error = function(e) list(error_class = class(e), message = conditionMessage(e)))

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
