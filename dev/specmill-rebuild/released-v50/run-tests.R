out <- 'dev/specmill-rebuild/released-v50'
Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false', ctx_api_key = '', CTX_API_KEY = '', http_proxy = 'http://127.0.0.1:9', https_proxy = 'http://127.0.0.1:9', HTTP_PROXY = 'http://127.0.0.1:9', HTTPS_PROXY = 'http://127.0.0.1:9', ALL_PROXY = 'http://127.0.0.1:9', no_proxy = '127.0.0.1,localhost', NO_PROXY = '127.0.0.1,localhost')
pkgload::load_all('.', quiet = TRUE)
stopifnot(!'specmill' %in% loadedNamespaces())
result <- testthat::test_local('.', filter = '^(native_descriptor_ownership|native_calculation|chemi_descriptor_contracts|pubchem_retained_http|pubchem_offline|chemi_search|native_chemi_search|native_chet_admin_auth|native_pagers|native_released_booleans_v45)$', reporter = 'summary', stop_on_failure = FALSE)
saveRDS(result, file.path(out, 'root-tests.rds'))
frame <- as.data.frame(result)
summary <- colSums(frame[, c('passed', 'failed', 'error', 'warning', 'skipped')])
print(summary)
stopifnot(!'specmill' %in% loadedNamespaces())
jsonlite::write_json(c(as.list(summary), list(specmill_runtime_loaded = FALSE)),
  file.path(out, 'root-tests.json'), auto_unbox = TRUE, pretty = TRUE)
stopifnot(all(summary[c('failed', 'error', 'warning', 'skipped')] == 0))
