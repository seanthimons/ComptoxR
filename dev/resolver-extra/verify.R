# Focused checks only. Set TMPDIR before launching R.
loadNamespace('specmill', lib.loc = Sys.getenv('SPECMILL_V41_LIBRARY', '/tmp/chet-specmill41-library'))
source('dev/generate_tests.R')
context <- new.env(parent = globalenv())
source_test_generation_pipeline(envir = context)
metadata <- context$tg_collect_wrapper_metadata('.')
bespoke <- context$tg_validate_bespoke_contracts(metadata, '.')
config <- yaml::read_yaml('apis/chemi-resolver-extra.yml')
names <- vapply(config$operations, `[[`, '', 'name')
stopifnot(length(names) == 12L, all(names %in% names(bespoke$suites)))
stopifnot(all(paste0('export(', names, ')') %in% readLines('NAMESPACE')))
for (name in names) {
  rd <- tools::parse_Rd(paste0('man/', name, '.Rd'))
  stopifnot(length(rd) > 0L)
}
proof <- jsonlite::read_json('dev/resolver-extra/generation-proof.json')
stopifnot(isTRUE(proof$fresh), isTRUE(proof$helper_matches_v41_scaffold),
  isTRUE(proof$validator_matches_worktree), proof$operations == 12L)
for (file in names(proof$owners)) {
  if (!file %in% c(vapply(config$operations, `[[`, '', 'file'), paste0('man/', names, '.Rd'))) next
  stopifnot(identical(digest::digest(paste(readLines(file, warn = FALSE), collapse = '\n'),
    algo = 'sha256', serialize = FALSE), proof$owners[[file]]$hash))
}
# All canonical references are local and resolve in the unchanged source closure.
canonical <- jsonlite::read_json('schema/chemi-resolver-prod.json')
check_refs <- function(node) {
  if (!is.list(node)) return(invisible(NULL))
  if (!is.null(node[['$ref']])) {
    ref <- node[['$ref']]
    stopifnot(startsWith(ref, '#/'))
    target <- canonical
    for (key in strsplit(sub('^#/', '', ref), '/', fixed = TRUE)[[1L]]) {
      key <- gsub('~1', '/', gsub('~0', '~', key, fixed = TRUE), fixed = TRUE)
      target <- target[[key]]
      stopifnot(!is.null(target))
    }
  }
  for (value in node) check_refs(value)
}
check_refs(canonical)

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
result <- withr::with_envvar(c(TESTTHAT_PARALLEL = 'FALSE'),
  testthat::test_local(filter = '^native_resolver_(extra|bodyless)$', stop_on_failure = TRUE, reporter = 'summary'))
summary <- as.data.frame(result)
stopifnot(!any(summary$failed), !any(summary$error), !any(summary$warning), !any(summary$skipped))
jsonlite::write_json(list(operations = 12L, localhost_only = TRUE, sequential_execution = TRUE,
  tests = nrow(summary), expectations = sum(summary$passed), failures = sum(summary$failed),
  errors = sum(summary$error), warnings = sum(summary$warning),
  scope = "12 resolver extra bindings", hooks_valid = TRUE, bespoke_registration_valid = TRUE, exports_and_rd_valid = TRUE,
  canonical_ref_closure_valid = TRUE, owned_wrappers_and_rd_hashes_valid = TRUE,
  fixture_sha256 = digest::digest(file = 'tests/testthat/fixtures/native-resolver-extra.rds', algo = 'sha256')),
  'dev/resolver-extra/test-proof.json', auto_unbox = TRUE, pretty = TRUE)
