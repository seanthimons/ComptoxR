root <- normalizePath(testthat::test_path('..', '..'), winslash = '/')
script <- file.path(root, 'dev/calculate_coverage.R')
if (!file.exists(script)) {
  testthat::skip('Maintainer-only coverage command is excluded from source archives')
}
source(script, local = TRUE)
source(file.path(root, 'dev/toolkit_adapter.R'), local = TRUE)

test_that('coverage uses selected operations and excludes manual exports from its denominator', {
  inventory <- comptox_inventory(root)
  totals <- vapply(inventory$coverage, `[[`, integer(1), 'total')
  implemented <- vapply(inventory$coverage, `[[`, integer(1), 'implemented')
  expect_equal(implemented, totals)
  expect_equal(sum(totals), length(inventory$operations))
  expect_gt(length(inventory$manual_exports), 0)
  report <- calculate_coverage(root, 'plan')
  expect_true(all(c('ccd_endpoints', 'chemi_endpoints', 'epi_endpoints') %in% names(report$baseline)))
  expect_equal(sum(unlist(report$baseline[grep('_endpoints$', names(report$baseline))])), sum(totals))
})
