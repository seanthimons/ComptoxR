Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false')
results <- testthat::test_local(
  filter = '^(native_small_families|native_received_http|specmill_adoption)$',
  stop_on_failure = TRUE,
  reporter = 'summary'
)
summary <- as.data.frame(results)
saveRDS(summary, 'dev/specmill-rebuild/small-families/test-results.rds', version = 2)
jsonlite::write_json(
  list(
    passed = sum(summary$passed),
    failed = sum(summary$failed),
    errors = sum(summary$error),
    warnings = sum(summary$warning),
    skipped = sum(summary$skipped),
    suites = unique(summary$file)
  ),
  'dev/specmill-rebuild/small-families/test-results.json',
  pretty = TRUE,
  auto_unbox = TRUE
)
