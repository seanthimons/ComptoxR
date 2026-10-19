Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS='true', NOT_CRAN='false', ctx_api_key='', CTX_API_KEY='', http_proxy='http://127.0.0.1:9', https_proxy='http://127.0.0.1:9', HTTP_PROXY='http://127.0.0.1:9', HTTPS_PROXY='http://127.0.0.1:9', ALL_PROXY='http://127.0.0.1:9', no_proxy='127.0.0.1,localhost', NO_PROXY='127.0.0.1,localhost')
out <- 'dev/specmill-rebuild/released-v50'
cache <- path.expand('~/.cache/comptoxr-specmill-finish')
snapshot <- file.path(cache, 'released50-package/ComptoxR')
lib <- file.path(cache, 'released50-library')
stage <- file.path(cache, 'released50-installed-tests/tests/testthat')
stopifnot(file.exists('R/chemi_chet_auth_login_post.R'), !dir.exists(snapshot), !dir.exists(lib))
dir.create(snapshot, recursive = TRUE)
dir.create(lib, recursive = TRUE)
dir.create(stage, recursive = TRUE)
for (directory in c('R', 'man', 'inst', 'data')) {
  if (dir.exists(directory)) stopifnot(file.copy(directory, snapshot, recursive = TRUE))
}
for (file in c('DESCRIPTION', 'NAMESPACE', 'LICENSE', 'LICENSE.md', '.Rbuildignore')) {
  if (file.exists(file)) stopifnot(file.copy(file, snapshot))
}
files <- c('test-api_token.R', 'helper-descriptor-contracts.R', 'test-chemi_search.R', 'test-native_chemi_search.R',
  'test-native_descriptor_ownership.R', 'test-native_calculation.R', 'test-chemi_descriptor_contracts.R', 'test-pubchem_retained_http.R', 'test-pubchem_offline.R', 'test-native_chet_admin_auth.R', 'test-native_pagers.R', 'test-native_released_booleans_v45.R')
stopifnot(all(file.copy(file.path('tests/testthat', files), stage)))
dir.create(file.path(stage, 'fixtures'), showWarnings = FALSE)
fixtures <- c('native-four-calculations-contracts.rds', 'native-ownership-contracts.rds', 'native-calculation-contracts.rds', 'pubchem-retained-originals.rds', 'chemi-search-legacy.R.txt', 'native-chet-admin-auth.rds',
  'native-pagers.rds', 'native-boolean-formals-v45.rds')
stopifnot(all(file.copy(file.path('tests/testthat/fixtures', fixtures), file.path(stage, 'fixtures'))))
stopifnot(!dir.exists(file.path(snapshot, 'schema')), !dir.exists(file.path(snapshot, 'dev')))
install.packages(snapshot, repos = NULL, type = 'source', lib = lib)
.libPaths(c(lib, .libPaths()))
ns <- loadNamespace('ComptoxR', lib.loc = lib)
stopifnot(identical(normalizePath(getNamespaceInfo(ns, 'path')), normalizePath(file.path(lib, 'ComptoxR'))),
  !'specmill' %in% loadedNamespaces())
result <- testthat::test_dir(stage, package = 'ComptoxR', load_package = 'installed',
  load_helpers = TRUE, reporter = 'summary', stop_on_failure = FALSE)
stopifnot(!'specmill' %in% loadedNamespaces())
saveRDS(result, file.path(out, 'installed-tests.rds'))
frame <- as.data.frame(result)
summary <- colSums(frame[, c('passed', 'failed', 'error', 'warning', 'skipped')])
print(summary)
jsonlite::write_json(list(result = as.list(summary), specmill_runtime_loaded = FALSE,
  installed_library = lib, source_schemas_in_snapshot = FALSE, source_dev_files_in_snapshot = FALSE),
  file.path(out, 'installed-tests.json'), auto_unbox = TRUE, pretty = TRUE)
stopifnot(summary[['passed']] > 200L, all(summary[c('failed', 'error', 'warning', 'skipped')] == 0L))
