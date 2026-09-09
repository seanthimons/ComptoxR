root <- normalizePath(testthat::test_path('..', '..'), winslash = '/')
script <- file.path(root, 'dev/generate_tests.R')
if (!file.exists(script)) {
  testthat::skip('Maintainer-only generation command is excluded from source archives')
}
source(script, local = TRUE)
source(file.path(root, 'dev/token_preflight.R'), local = TRUE)

test_that('selected fixed contracts are current and report successful CI fields', {
  output <- withr::local_tempfile()
  withr::local_envvar(c(GITHUB_OUTPUT = output))
  expect_no_error(generate_tests_main('--check', root))
  expect_true(all(c('check_status=pass', 'gaps_remaining=0', 'tests_generated=0') %in% readLines(output)))
})

test_that('recording token preflight still rejects placeholders without logging values', {
  for (value in c('', 'dummy_ctx_key', '<<<API_KEY>>>', 'xxxxxxxx')) {
    expect_false(ctx_api_key_status(value)$valid)
  }
  expect_true(ctx_api_key_status('realistic-token-value-123')$valid)
  error <- rlang::catch_cnd(ctx_api_key_preflight('dummy-do-not-log'))
  expect_s3_class(error, 'error')
  expect_false(grepl('dummy-do-not-log', conditionMessage(error), fixed = TRUE))
})
