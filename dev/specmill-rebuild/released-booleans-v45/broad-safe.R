# Exercise the package without remote requests or local integration resources.
out <- 'dev/specmill-rebuild/released-booleans-v45'
Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false', ctx_api_key = '',
  CTX_API_KEY = '', http_proxy = 'http://127.0.0.1:9', https_proxy = 'http://127.0.0.1:9',
  HTTP_PROXY = 'http://127.0.0.1:9', HTTPS_PROXY = 'http://127.0.0.1:9',
  ALL_PROXY = 'http://127.0.0.1:9', all_proxy = 'http://127.0.0.1:9',
  no_proxy = '127.0.0.1,localhost', NO_PROXY = '127.0.0.1,localhost')
result <- devtools::test('.', reporter = 'summary', stop_on_failure = FALSE)
saveRDS(result, file.path(out, 'broad-safe-tests.rds'))
frame <- as.data.frame(result)
write.csv(frame[, intersect(c('file', 'context', 'test', 'nb', 'failed', 'skipped',
  'error', 'warning', 'passed', 'real'), names(frame))], file.path(out, 'broad-safe-tests.csv'), row.names = FALSE)
summary <- colSums(frame[, c('failed', 'error', 'warning', 'passed', 'skipped')])
print(summary)
jsonlite::write_json(c(as.list(summary), list(test_cases = nrow(frame),
  test_files = length(unique(frame$file)), specmill_version = '0.1.45',
  external_http_blocked = TRUE, api_keys_blank = TRUE, localhost_allowed = TRUE)),
  file.path(out, 'broad-safe-summary.json'), auto_unbox = TRUE, pretty = TRUE)
stopifnot(all(summary[c('failed', 'error', 'warning')] == 0L))
