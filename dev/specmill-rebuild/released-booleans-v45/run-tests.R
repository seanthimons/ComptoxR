out <- 'dev/specmill-rebuild/released-booleans-v45'
result <- testthat::test_local('.', filter = '^(native_released_booleans_v45|native_stdizer_protocol_search|native_stdizer_protocol_get)$', reporter = 'summary', stop_on_failure = FALSE)
saveRDS(result, file.path(out, 'root-tests.rds'))
frame <- as.data.frame(result)
summary <- colSums(frame[, c('passed', 'failed', 'error', 'warning', 'skipped')])
print(summary)
jsonlite::write_json(as.list(summary), file.path(out, 'root-tests.json'), auto_unbox = TRUE, pretty = TRUE)
stopifnot(summary[['passed']] > 200L, all(summary[c('failed', 'error', 'warning', 'skipped')] == 0L))
