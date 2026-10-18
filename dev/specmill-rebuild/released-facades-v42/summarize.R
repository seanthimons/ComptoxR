source('dev/specmill-rebuild/released-facades-v42/setup.R')
loadNamespace('testthat')
generation <- readRDS(file.path(folder, 'generation.rds'))
manifest <- generation$ownership
for (path in names(manifest$files)) {
  actual <- if (path == 'NAMESPACE') file.path(folder, 'isolated-NAMESPACE.txt') else path
  stopifnot(identical(specmill:::output_hash(actual), manifest$files[[path]]$hash))
}
matrix <- readRDS(file.path(folder, 'results.rds'))
stopifnot(length(matrix) == 554L, sum(vapply(matrix, `[[`, FALSE, 'equal')) == 518L,
  all(vapply(Filter(function(x) !x$equal, matrix), function(x) identical(x$status, 401L), FALSE)))
tests <- as.data.frame(readRDS(file.path(folder, 'tests.rds')))
stopifnot(!any(tests$error), !any(tests$failed), !any(tests$warning), !any(tests$skipped))
whole <- readRDS(file.path(folder, 'whole-client.rds'))
report <- list(
  base = 'cd34efb4', minimum_specmill = '0.1.42',
  source = metadata[['Config/specmill/source-commit']],
  source_archive_sha256 = metadata[['Config/specmill/source-archive-sha256']],
  official_tar_sha256 = '0d1be547b950fb807b1a8d027199651304fb74e30fdde9e487a3a99a10e37aa8',
  selected_operations = length(generation$generation$operations), migrated_facades = 8L,
  scoped_owned_hashes = length(manifest$files),
  scoped_fresh_files = length(generation$freshness$files),
  matrix = list(cases = length(matrix), exact = 518L, intentional_native_hard401 = 36L),
  tests = list(passed = sum(tests$passed), failed = sum(tests$failed), errors = sum(tests$error),
    warnings = sum(tests$warning), skipped = sum(tests$skipped)),
  whole_client = list(owned_hashes = length(whole$manifest$files), fresh_files = length(whole$freshness$files),
    validation = stats::setNames(lapply(whole$generation$validation, `[[`, 'status'), basename(names(whole$generation$validation)))),
  metadata_inventory = list(legacy_wrappers = 12L, current = TRUE),
  metadata_renderer_followup = 'https://github.com/seanthimons/specmill/issues/182',
  new_blocker = 'https://github.com/seanthimons/specmill/issues/181',
  preserved = jsonlite::read_json(file.path(folder, 'untouched.json')),
  full_package_check = FALSE, deployed_calls = FALSE, push = FALSE)
jsonlite::write_json(report, file.path(folder, 'verification.json'), auto_unbox = TRUE, pretty = TRUE)
print(report[c('migrated_facades', 'scoped_owned_hashes', 'matrix', 'tests', 'whole_client')])
