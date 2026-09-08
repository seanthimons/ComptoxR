# Run from the frozen migration checkout before endpoint edits.
migration_baseline <- function() {
  Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false')
  Sys.unsetenv('ctx_api_key')
  dir.create('dev/reports/migration', recursive = TRUE, showWarnings = FALSE)
  files <- system2('git', 'ls-files', stdout = TRUE)
  hashes <- data.frame(path = files, md5 = unname(tools::md5sum(files)))
  utils::write.csv(hashes, 'dev/reports/migration/baseline-files.csv', row.names = FALSE)
  writeLines(capture.output(sessionInfo()), 'dev/reports/migration/session-info.txt')
  result <- devtools::test(
    filter = 'generic_request|generic_chemi_request|exported_utility_contracts|package_sitrep|chemi_descriptor|probe_api_function|hooks_stage_server|eco_connection|tox_connection|eco_functions|tox_functions',
    reporter = 'summary',
    stop_on_failure = FALSE
  )
  saveRDS(result, 'dev/reports/migration/endpoint-baseline.rds')
  migration_baseline_report(result)
  invisible(result)
}

migration_baseline_report <- function(result = readRDS('dev/reports/migration/endpoint-baseline.rds')) {
  loadNamespace('testthat')
  report <- as.data.frame(result)
  report$result <- NULL
  utils::write.csv(report, 'dev/reports/migration/endpoint-baseline.csv', row.names = FALSE)
  print(colSums(report[c('failed', 'skipped', 'error', 'warning', 'passed')]))
}

if (sys.nframe() == 0L) {
  migration_baseline()
}
