root <- normalizePath(testthat::test_path('..', '..'), winslash = '/')
script <- file.path(root, 'dev/toolkit_adapter.R')
if (!file.exists(script)) {
  testthat::skip('Maintainer-only schema policy is excluded from source archives')
}
source(script, local = TRUE)
source(file.path(root, 'dev/check_public_api.R'), local = TRUE)

test_that('all selected public operations have exported implementations and fixed contracts', {
  inventory <- comptox_inventory(root)
  expect_true(all(vapply(inventory$operations, `[[`, logical(1), 'implemented')))
  expect_true(all(vapply(inventory$operations, `[[`, logical(1), 'contract_declared')))
  expect_true(all(vapply(inventory$operations, function(x) !is.null(x$contract_file), logical(1))))
  expect_true(all(vapply(
    inventory$inventory,
    function(x) x$status %in% c('selected', 'excluded', 'client-mapped', 'retained-unsupported'),
    logical(1)
  )))
  expect_true(check_public_api(root))
})
