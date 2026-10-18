# Summarize exact comparisons, including all output names and attributes.
directory <- 'dev/specmill-rebuild/rootheldrelease'
results <- readRDS(file.path(directory, 'results.rds'))
baseline <- readRDS(file.path(directory, 'authentic-baseline.rds'))
classify <- function(x) {
  if (x$equal) return('exact')
  if (identical(x$status, 401L)) return('intentional_native_hard401')
  stop('Unresolved difference: ', x$name, ' ', paste(x$args, collapse = ';'))
}
counts <- table(vapply(results, classify, ''))
stopifnot(length(baseline) == 490L, sum(vapply(baseline, `[[`, FALSE, 'equal')) == 400L,
  length(results) == 554L, counts[['exact']] == 518L,
  counts[['intentional_native_hard401']] == 36L)
files <- list.files(directory, full.names = TRUE)
files <- files[!dir.exists(files) & basename(files) != 'summary.json']
runtime_files <- c('schema/chemi-chet-prod.json', 'R/z_generic_request.R', 'R/z_specmill_request.R',
  'R/hook_registry.R', 'R/input_policy.R', 'R/batch_failure_policy.R',
  'R/chemi_chet_reaction_searchcounts.R', 'R/chemi_chet_reaction_database_old_by_pagenum_and_searchterm.R',
  'dev/specmill-lock.json', 'specmill.yml')
summary <- list(
  status = 'Client parity resolved except intentional native hard401; ready for released adoption and parent pin update',
  source = jsonlite::read_json(file.path(directory, 'toolkit-lock.json')),
  frozen_fixture_commit = 'a79a16b8',
  package_base_commit = system2('git', c('rev-parse', 'HEAD'), stdout = TRUE),
  unchanged_runtime_sha256 = as.list(setNames(vapply(runtime_files,
    function(f) digest::digest(file = f, algo = 'sha256'), ''), runtime_files)),
  authentic_baseline = list(cases = 490L, exact = 400L, retracted_names_artifacts = 24L),
  diagnostics = as.list(counts),
  interpretation = '554 exact diagnostic comparisons: 518 exact matches and 36 intentional native hard401 differences; no output attributes stripped',
  focused_assertions = readLines(file.path(directory, 'focused-check.txt')),
  executor_assertion = readLines(file.path(directory, 'executor-check.txt')),
  httr2_version = as.character(utils::packageVersion('httr2')),
  generation = 'official exact-archive emitter; no operation/mapping/drift diagnostics; byte-for-byte regeneration passed',
  files_sha256 = as.list(setNames(vapply(files, function(f) digest::digest(file = f, algo = 'sha256'), ''), basename(files)))
)
jsonlite::write_json(summary, file.path(directory, 'summary.json'), auto_unbox = TRUE, pretty = TRUE)
print(counts)
