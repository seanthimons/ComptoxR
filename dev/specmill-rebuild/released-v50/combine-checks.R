loadNamespace('testthat')
out <- 'dev/specmill-rebuild/released-v50'
original <- as.data.frame(readRDS(file.path(out, 'initial-three-stale-assertions-broad-safe-tests.rds')))
corrective <- as.data.frame(readRDS(file.path(out, 'corrective-tests.rds')))
failed <- original[original$failed > 0L | original$error | original$warning, ]
stopifnot(nrow(failed) == 1L, identical(basename(failed$file), 'test-retained_search_safety.R'),
  failed$failed == 3L, !failed$error, failed$warning == 0L,
  all(corrective$failed == 0L), !any(corrective$error), !any(corrective$warning), !any(corrective$skipped))
replaced <- unique(basename(corrective$file))
combined <- rbind(original[!basename(original$file) %in% replaced, ], corrective)
summary <- colSums(combined[, c('passed', 'failed', 'error', 'warning', 'skipped')])
stopifnot(summary[['passed']] == 14114L, summary[['skipped']] == 50L,
  all(summary[c('failed', 'error', 'warning')] == 0L))
saveRDS(combined, file.path(out, 'combined-safe-tests.rds'))
write.csv(combined[, c('file', 'test', 'passed', 'failed', 'error', 'warning', 'skipped')],
  file.path(out, 'combined-safe-tests.csv'), row.names = FALSE)
jsonlite::write_json(list(result = as.list(summary), verification =
  'Completed broad run plus focused replacement suites, not a second full-suite invocation.',
  broad_original = list(passed = 14099L, failed = 3L, errors = 0L, warnings = 0L, skips = 50L),
  corrective = list(passed = 395L, failed = 0L, errors = 0L, warnings = 0L, skips = 0L),
  replaced_files = replaced, source_credential_test_added_after_broad_start = TRUE,
  runtime_changed_after_broad_start = FALSE, retired_case = 'search-test-retirement.json',
  cases = nrow(combined), files = length(unique(combined$file))),
  file.path(out, 'combined-safe-summary.json'), pretty = TRUE, auto_unbox = TRUE)
print(summary)
