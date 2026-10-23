Sys.setenv(COMPTOXR_WEBTEST_EVIDENCE = normalizePath('dev/specmill-rebuild/webtest-exports', mustWork = TRUE))
Sys.setenv(COMPTOXR_WEBTEST_EVIDENCE = file.path(Sys.getenv('COMPTOXR_WEBTEST_EVIDENCE'), 'localhost-wire.rds'))
Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false')
results <- testthat::test_local(filter = '^(native_webtest_exports|hooks-webtest|native_small_families)$',
  stop_on_failure = TRUE, reporter = 'summary')
summary <- as.data.frame(results)
jsonlite::write_json(list(passed = sum(summary$passed), failed = sum(summary$failed),
  errors = sum(summary$error), warnings = sum(summary$warning), skipped = sum(summary$skipped),
  suites = unique(summary$file)), 'dev/specmill-rebuild/webtest-exports/tests.json',
  pretty = TRUE, auto_unbox = TRUE)
