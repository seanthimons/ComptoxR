# Focused checks only. Set TMPDIR before launching R.
loadNamespace('specmill', lib.loc = Sys.getenv('SPECMILL_V41_LIBRARY', '/tmp/chet-specmill41-library'))
source('dev/generate_tests.R')
context <- new.env(parent = globalenv())
source_test_generation_pipeline(envir = context)
metadata <- context$tg_collect_wrapper_metadata('.')
bespoke <- context$tg_validate_bespoke_contracts(metadata, '.')
config <- yaml::read_yaml('apis/chemi-search-services-native.yml')
new_names <- vapply(config$operations, `[[`, '', 'name')
names <- c(new_names, 'chemi_services_convert', 'chemi_services_collated_report')
stopifnot(length(names) == 13L, all(names %in% names(bespoke$suites)))
stopifnot(all(paste0('export(', names, ')') %in% readLines('NAMESPACE')))
for (name in names) {
  rd <- tools::parse_Rd(paste0('man/', name, '.Rd'))
  stopifnot(length(rd) > 0L)
}
proof <- jsonlite::read_json('dev/search-services/generation-proof.json')
stopifnot(isTRUE(proof$fresh), isTRUE(proof$helper_matches_v41_scaffold),
  isTRUE(proof$validator_matches_worktree), proof$operations == 11L)
for (file in names(proof$owners)) {
  if (!file %in% c(vapply(config$operations, `[[`, '', 'file'), paste0('man/', names, '.Rd'))) next
  stopifnot(identical(digest::digest(paste(readLines(file, warn = FALSE), collapse = '\n'),
    algo = 'sha256', serialize = FALSE), proof$owners[[file]]$hash))
}
# All canonical references are local and resolve in the unchanged source closure.
canonical <- jsonlite::read_json('schema/chemi-services-reviewed-preflight.json')
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
wrappers <- lapply(names, function(name) {
  expressions <- parse(paste0('R/', name, '.R'))
  definition <- Filter(function(x) is.call(x) && identical(x[[1L]], as.name('<-')), as.list(expressions))[[1L]]
  eval(definition[[3L]], baseenv())
})
names(wrappers) <- names
stopifnot(specmill::validate_hooks(hooks, wrappers, new.env(parent = baseenv()))$valid)
result <- testthat::test_local(filter = '^native_(search_services|services_legacy)$', stop_on_failure = TRUE, reporter = 'summary')
summary <- as.data.frame(result)
stopifnot(!any(summary$failed), !any(summary$error), !any(summary$warning), !any(summary$skipped))
jsonlite::write_json(list(operations = 13L, localhost_only = TRUE,
  tests = nrow(summary), expectations = sum(summary$passed), failures = sum(summary$failed),
  errors = sum(summary$error), warnings = sum(summary$warning),
  scope = "11 new search/services bindings and two corrected legacy services", hooks_valid = TRUE, bespoke_registration_valid = TRUE, exports_and_rd_valid = TRUE,
  canonical_ref_closure_valid = TRUE, owned_wrappers_and_rd_hashes_valid = TRUE,
  fixture_sha256 = digest::digest(file = 'tests/testthat/fixtures/native-search-services.rds', algo = 'sha256')),
  'dev/search-services/test-proof.json', auto_unbox = TRUE, pretty = TRUE)

legacy <- jsonlite::read_json('dev/search-services/legacy-generation-proof.json')
stopifnot(legacy$operations == 2L, isTRUE(legacy$fresh))
for (file in names(legacy$owners)) {
  if (!grepl('^R/chemi_services_(convert|collated_report)[.]R$|^man/', file)) next
  stopifnot(identical(digest::digest(paste(readLines(file), collapse = '\n'), algo = 'sha256', serialize = FALSE), legacy$owners[[file]]$hash))
}
