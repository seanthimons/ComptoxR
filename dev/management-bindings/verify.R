# Focused checks only. Set TMPDIR before launching R.
loadNamespace('specmill', lib.loc = Sys.getenv('SPECMILL_V41_LIBRARY', '/tmp/chet-specmill41-library'))
source('dev/generate_tests.R')
context <- new.env(parent = globalenv())
source_test_generation_pipeline(envir = context)
metadata <- context$tg_collect_wrapper_metadata('.')
bespoke <- context$tg_validate_bespoke_contracts(metadata, '.')
config <- yaml::read_yaml('apis/chemi-management.yml')
names <- vapply(config$operations, `[[`, '', 'name')
stopifnot(length(names) == 24L, all(names %in% names(bespoke$suites)))
selected_errors <- Filter(function(error) any(startsWith(error, paste0(names, ':'))), bespoke$errors)
stopifnot(!length(selected_errors))
hooks <- yaml::read_yaml('inst/hook_config.yml')[names]
wrappers <- lapply(config$operations, function(op) {
  expressions <- parse(op$file)
  definition <- Filter(function(x) is.call(x) && identical(x[[1L]], as.name('<-')), as.list(expressions))[[1L]]
  eval(definition[[3L]], baseenv())
})
names(wrappers) <- names
stopifnot(specmill::validate_hooks(hooks, wrappers, new.env(parent = baseenv()))$valid)
result <- testthat::test_local(filter = '^native_management$', stop_on_failure = TRUE, reporter = 'summary')
summary <- as.data.frame(result)
stopifnot(!any(summary$failed), !any(summary$error), !any(summary$warning), !any(summary$skipped))
jsonlite::write_json(list(operations = 24L, localhost_only = TRUE,
  tests = nrow(summary), expectations = sum(summary$passed), failures = sum(summary$failed),
  errors = sum(summary$error), warnings = sum(summary$warning),
  scope = "24 management bindings", hooks_valid = TRUE, bespoke_registration_valid = TRUE,
  fixture_sha256 = digest::digest(file = 'tests/testthat/fixtures/native-management.rds', algo = 'sha256')),
  'dev/management-bindings/test-proof.json', auto_unbox = TRUE, pretty = TRUE)
