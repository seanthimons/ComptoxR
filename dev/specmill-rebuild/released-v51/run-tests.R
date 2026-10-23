out <- 'dev/specmill-rebuild/released-v51'
Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false', ctx_api_key = '', CTX_API_KEY = '', http_proxy = 'http://127.0.0.1:9', https_proxy = 'http://127.0.0.1:9', HTTP_PROXY = 'http://127.0.0.1:9', HTTPS_PROXY = 'http://127.0.0.1:9', ALL_PROXY = 'http://127.0.0.1:9', no_proxy = '127.0.0.1,localhost', NO_PROXY = '127.0.0.1,localhost')
pkgload::load_all('.', quiet = TRUE)
stopifnot(!'specmill' %in% loadedNamespaces())
result <- testthat::test_local('.', filter = '^native_descriptor_ownership$', reporter = 'summary', stop_on_failure = FALSE)
saveRDS(result, file.path(out, 'root-tests.rds'))
frame <- as.data.frame(result)
summary <- colSums(frame[, c('passed', 'failed', 'error', 'warning', 'skipped')])
print(summary)
stopifnot(!'specmill' %in% loadedNamespaces())
jsonlite::write_json(c(as.list(summary), list(specmill_runtime_loaded = FALSE)),
  file.path(out, 'root-tests.json'), auto_unbox = TRUE, pretty = TRUE)
stopifnot(all(summary[c('failed', 'error', 'warning', 'skipped')] == 0))
