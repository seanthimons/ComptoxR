out <- 'dev/specmill-rebuild/released-facades-v47'
Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false', ctx_api_key = '', CTX_API_KEY = '')
pkgload::load_all('.', quiet = TRUE)
stopifnot(!'specmill' %in% loadedNamespaces())
result <- testthat::test_local('.', filter = '^(chemi_search|native_chemi_search|native_chet_admin_auth|native_pagers|native_released_booleans_v45)$', reporter = 'summary', stop_on_failure = FALSE)
saveRDS(result, file.path(out, 'root-tests.rds'))
frame <- as.data.frame(result)
summary <- colSums(frame[, c('passed', 'failed', 'error', 'warning', 'skipped')])
print(summary)
stopifnot(!'specmill' %in% loadedNamespaces())
jsonlite::write_json(c(as.list(summary), list(specmill_runtime_loaded = FALSE)),
  file.path(out, 'root-tests.json'), auto_unbox = TRUE, pretty = TRUE)
stopifnot(all(summary[c('failed', 'error', 'warning', 'skipped')] == 0))
