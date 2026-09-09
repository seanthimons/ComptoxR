root <- normalizePath(testthat::test_path('..', '..'), winslash = '/')
script <- file.path(root, 'dev/check_hook_config.R')
if (!file.exists(script)) {
  testthat::skip('Maintainer-only hook command is excluded from source archives')
}
source(script, local = TRUE)

test_that('generated wrappers retain the configured hook stages and request fields', {
  result <- check_hook_config(root)
  expect_true(result$valid)
  expect_gt(result$hooks, 0)
  expect_gt(result$parameters, 0)
})
