out <- 'dev/specmill-rebuild/canonical-holds-audit/protocol-paging-recheck'
mode <- commandArgs(TRUE)[[1L]]
if (mode == 'candidate') {
  env <- new.env(parent = globalenv())
  work <- path.expand('~/.cache/comptoxr-specmill-finish/protocol-search-candidate')
  for (file in c('R/api_validation.R', 'R/z_specmill_request.R', 'R/service_endpoints.R', 'R/api_auth.R', 'R/stdizer_protocol_policy.R')) sys.source(file, env)
  sys.source(file.path(work, 'R/chemi_stdizer_protocols_by_id_post.R'), env)
  result <- testthat::test_file('tests/testthat/test-native_stdizer_protocol_search.R', env = env, reporter = 'summary')
} else {
  stopifnot(mode == 'root')
  result <- testthat::test_local('.', filter = '^native_stdizer_protocol_search$', reporter = 'summary', stop_on_failure = FALSE)
}
saveRDS(result, file.path(out, paste0(mode, '-tests.rds')))
frame <- as.data.frame(result)
summary <- colSums(frame[, c('passed', 'failed', 'error', 'warning', 'skipped')])
print(summary)
jsonlite::write_json(as.list(summary), file.path(out, paste0(mode, '-tests.json')), pretty = TRUE, auto_unbox = TRUE)
stopifnot(summary[['passed']] > 40L, all(summary[c('failed', 'error', 'warning', 'skipped')] == 0L))
