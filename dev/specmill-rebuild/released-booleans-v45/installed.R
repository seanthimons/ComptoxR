out <- 'dev/specmill-rebuild/released-booleans-v45'
cache <- path.expand('~/.cache/comptoxr-specmill-finish')
snapshot <- file.path(cache, 'released45-package/ComptoxR')
lib <- file.path(cache, 'released45-library')
stage <- file.path(cache, 'released45-installed-tests/tests/testthat')
stopifnot(file.exists('R/chemi_stdizer_protocols_by_id_post.R'), !dir.exists(snapshot), !dir.exists(lib))
dir.create(snapshot, recursive = TRUE)
dir.create(lib, recursive = TRUE)
dir.create(stage, recursive = TRUE)
for (directory in c('R', 'man', 'inst', 'data')) {
  if (dir.exists(directory)) stopifnot(file.copy(directory, snapshot, recursive = TRUE))
}
for (file in c('DESCRIPTION', 'NAMESPACE', 'LICENSE', 'LICENSE.md', '.Rbuildignore')) {
  if (file.exists(file)) stopifnot(file.copy(file, snapshot))
}
stopifnot(all(file.copy(c('tests/testthat/test-native_stdizer_protocol_search.R',
  'tests/testthat/test-native_released_booleans_v45.R',
  'tests/testthat/test-native_stdizer_protocol_get.R'), stage)))
dir.create(file.path(stage, 'fixtures'), showWarnings = FALSE)
stopifnot(file.copy('tests/testthat/fixtures/native-boolean-formals-v45.rds', file.path(stage, 'fixtures')))
stopifnot(!dir.exists(file.path(snapshot, 'schema')), !dir.exists(file.path(snapshot, 'dev')))
install.packages(snapshot, repos = NULL, type = 'source', lib = lib)
.libPaths(c(lib, .libPaths()))
ns <- loadNamespace('ComptoxR', lib.loc = lib)
stopifnot(identical(normalizePath(getNamespaceInfo(ns, 'path')), normalizePath(file.path(lib, 'ComptoxR'))),
  !'specmill' %in% loadedNamespaces())
result <- testthat::test_dir(stage, package = 'ComptoxR', load_package = 'installed',
  load_helpers = FALSE, reporter = 'summary', stop_on_failure = FALSE)
stopifnot(!'specmill' %in% loadedNamespaces())
saveRDS(result, file.path(out, 'installed-tests.rds'))
frame <- as.data.frame(result)
summary <- colSums(frame[, c('passed', 'failed', 'error', 'warning', 'skipped')])
print(summary)
jsonlite::write_json(list(result = as.list(summary), specmill_runtime_loaded = FALSE,
  installed_library = lib, source_schemas_in_snapshot = FALSE, source_dev_files_in_snapshot = FALSE),
  file.path(out, 'installed-tests.json'), auto_unbox = TRUE, pretty = TRUE)
stopifnot(summary[['passed']] > 200L, all(summary[c('failed', 'error', 'warning', 'skipped')] == 0L))
