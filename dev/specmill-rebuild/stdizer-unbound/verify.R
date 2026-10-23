source('dev/install_specmill.R')
verify_specmill()
source('dev/generate_tests.R')
context <- new.env(parent = globalenv())
source_test_generation_pipeline(envir = context)
metadata <- context$tg_collect_wrapper_metadata('.')
bespoke <- context$tg_validate_bespoke_contracts(metadata, '.')
config <- yaml::read_yaml('apis/chemi-stdizer-unbound.yml')
wrappers <- vapply(config$operations, `[[`, '', 'name')
for (operation in config$operations) tools::checkRd(paste0('man/', operation$name, '.Rd'))
stopifnot(length(wrappers) == 15L, all(wrappers %in% names(bespoke$suites)),
  !length(Filter(function(error) any(startsWith(error, paste0(wrappers, ':'))), bespoke$errors)))
manifest <- jsonlite::read_json('dev/specmill-rebuild/stdizer-unbound/ownership.json')$files
root_manifest <- jsonlite::read_json('.specmill/manifest.json')$files
for (records in list(manifest, root_manifest)) for (file in names(records)) {
  target <- if (identical(records, manifest) && file == 'NAMESPACE') 'dev/specmill-rebuild/stdizer-unbound/isolated-NAMESPACE.txt' else file
  stopifnot(identical(specmill:::output_hash(target), records[[file]]$hash))
}
result <- testthat::test_local(filter = '^(native_stdizer_unbound|contract-chemi_stdizer.*|chemi_stdizer.*)$',
  stop_on_failure = TRUE, reporter = 'summary')
summary <- as.data.frame(result)
stopifnot(!any(summary$failed), !any(summary$error), !any(summary$warning), !any(summary$skipped))
saveRDS(result, 'dev/specmill-rebuild/stdizer-unbound/test-results.rds')
jsonlite::write_json(list(tests = nrow(summary), passed = sum(summary$passed),
  failed = sum(summary$failed), errors = sum(summary$error), warnings = sum(summary$warning),
  skipped = sum(summary$skipped), registered = wrappers, scoped_owned = length(manifest),
  root_owned = length(root_manifest)), 'dev/specmill-rebuild/stdizer-unbound/test-proof.json',
  pretty = TRUE, auto_unbox = TRUE)
