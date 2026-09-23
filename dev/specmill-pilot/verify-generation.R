# Run after the initial reviewed adoption, from the package root.
source('dev/generate_specmill.R')
source('dev/install_specmill.R')
verify_specmill()
stopifnot(file.exists('.specmill/manifest.json'))
root <- normalizePath('.')
baseline <- file.path(root, 'dev/specmill-pilot/artifacts/before-source')
stopifnot(dir.exists(baseline))
paths <- c('R', 'man', 'NAMESPACE', 'inst', 'schema', 'data', 'data-raw', 'tests', '.specmill', '.wrapmaint')
hashes <- function(directory, selected = paths) {
  files <- unlist(
    lapply(selected, function(path) {
      full <- file.path(directory, path)
      if (dir.exists(full)) {
        file.path(path, list.files(full, recursive = TRUE, all.files = TRUE))
      } else if (file.exists(full)) {
        path
      } else {
        character()
      }
    }),
    use.names = FALSE
  )
  files <- sort(files[!dir.exists(file.path(directory, files))])
  setNames(vapply(file.path(directory, files), digest::digest, '', file = TRUE, algo = 'sha256'), files)
}
# Compare every pre-existing runtime, documentation, schema, hook and data file.
old <- hashes(baseline, setdiff(paths, c('tests', '.specmill')))
now <- hashes(root, setdiff(paths, c('tests', '.specmill')))
stopifnot(all(names(old) %in% names(now)))
changed <- names(old)[old != now[names(old)]]
allowed <- c(
  names(jsonlite::read_json('dev/specmill-pilot/adoption-hashes.json')),
  names(jsonlite::read_json('dev/specmill-pilot/adoption-hashes-lookup-expansion.json'))
)
stopifnot(setequal(changed, allowed))
for (file in allowed) {
  badge <- grep('lifecycle::badge', readLines(file.path(baseline, file)), value = TRUE)
  stopifnot(length(badge) > 0L, all(badge %in% readLines(file)))
}
before <- hashes(root)
generate_specmill('apply')
stopifnot(identical(before, hashes(root)))
generate_specmill('check')
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
inspection <- specmill::inspect_client(root, config = 'specmill.yml', callbacks = callbacks)
inspection_again <- specmill::inspect_client(root, config = 'specmill.yml', callbacks = callbacks)
stopifnot(
  identical(before, hashes(root)),
  identical(inspection$helpers, inspection_again$helpers),
  all(vapply(inspection$helpers, function(x) identical(x$baseline, 'unknown'), FALSE))
)

# Negative cases use disposable copies. Source schemas stay byte-identical.
local({
  temporary <- tempfile('specmill-ownership-')
  dir.create(temporary)
  on.exit(unlink(temporary, recursive = TRUE), add = TRUE)
  copy_client <- function(name) {
    target <- file.path(temporary, name)
    dir.create(target)
    inputs <- c(
      'R',
      'man',
      'data',
      'inst',
      'schema',
      'apis',
      'tests',
      '.specmill',
      'DESCRIPTION',
      'NAMESPACE',
      'specmill.yml',
      'air.toml'
    )
    stopifnot(all(file.copy(file.path(root, inputs), target, recursive = TRUE)))
    dir.create(file.path(target, 'dev'))
    stopifnot(file.copy(file.path(root, 'dev/specmill_callbacks.R'), file.path(target, 'dev')))
    target
  }
  run <- function(target, adopt = list()) {
    specmill::generate_client(
      target,
      config = 'specmill.yml',
      callbacks = callbacks,
      mode = 'apply',
      artifacts = c('wrappers', 'tests'),
      adopt = adopt
    )
  }
  stale <- copy_client('stale-adoption')
  file <- 'R/epi_search.R'
  adoption <- setNames(list(specmill:::output_hash(file.path(stale, file))), file)
  cat('\n# Local edit after adoption review\n', file = file.path(stale, file), append = TRUE)
  previous <- hashes(stale)
  error <- tryCatch(run(stale, adoption), error = identity)
  stopifnot(
    inherits(error, 'error'),
    grepl('adoption hash differs', conditionMessage(error)),
    identical(previous, hashes(stale))
  )
  stale_diagnostic <- conditionMessage(error)

  protected <- copy_client('protected-independent')
  cat('\n# lifecycle::badge("stable")\n', file = file.path(protected, file), append = TRUE)
  protected_hash <- hashes(protected)[[file]]
  unlink(file.path(protected, 'R/chemi_alerts_groups_by_id.R'))
  result <- run(protected)
  stopifnot(
    identical(protected_hash, hashes(protected)[[file]]),
    file.exists(file.path(protected, 'R/chemi_alerts_groups_by_id.R'))
  )

  # A changed declared public default conflicts with the protected implementation.
  policy <- file.path(protected, 'apis/epi-pilot.yml')
  settings <- readLines(policy)
  stopifnot(sum(grepl('default: 20.0', settings, fixed = TRUE)) == 1L)
  writeLines(sub('default: 20.0', 'default: 21.0', settings, fixed = TRUE), policy)
  previous <- hashes(protected)
  error <- tryCatch(run(protected), error = identity)
  if (inherits(error, 'error')) {
    message('Protected contract conflict: ', conditionMessage(error))
  }
  stopifnot(
    inherits(error, 'error'),
    grepl('public contract differs', conditionMessage(error)),
    identical(previous, hashes(protected))
  )
  conflict_diagnostic <- conditionMessage(error)
  blocked <- copy_client('blocked-independent')
  config_file <- file.path(blocked, 'specmill.yml')
  config <- yaml::read_yaml(config_file)
  config$services <- c(config$services, 'apis/blocked.yml')
  config$callback_files <- as.list(config$callback_files)
  yaml::write_yaml(config, config_file)
  yaml::write_yaml(
    list(
      id = 'blocked-stdizer',
      schemas = list(files = list('schema/chemi-stdizer-prod.json')),
      selection = list(include = list('GET /api/stdizer/protocols/{id}')),
      helper = 'generic_request'
    ),
    file.path(blocked, 'apis/blocked.yml')
  )
  unlink(file.path(blocked, 'R/chemi_alerts_groups_by_id.R'))
  result <- specmill::generate_client(
    blocked,
    config = 'specmill.yml',
    callbacks = callbacks,
    mode = 'plan',
    artifacts = 'wrappers'
  )
  rejected <- Filter(function(x) identical(x$key, 'GET /api/stdizer/protocols/{id}'), result$diagnostics)
  stopifnot(
    length(rejected) == 1L,
    identical(rejected[[1L]]$code, 'nested_parameter'),
    !any(vapply(
      result$operations,
      function(x) {
        identical(x$key, 'GET /api/stdizer/protocols/{id}')
      },
      FALSE
    ))
  )
  previous <- hashes(blocked)
  mixed_error <- tryCatch(
    specmill::generate_client(
      blocked,
      config = 'specmill.yml',
      callbacks = callbacks,
      mode = 'apply',
      artifacts = 'wrappers'
    ),
    error = identity
  )
  stopifnot(
    inherits(mixed_error, 'error'),
    grepl('Unsupported selected operations', conditionMessage(mixed_error)),
    identical(previous, hashes(blocked))
  )
  # Scope the apply to the reviewed supported services after recording rejection.
  stopifnot(file.copy(file.path(root, 'specmill.yml'), config_file, overwrite = TRUE))
  run(blocked)
  stopifnot(file.exists(file.path(blocked, 'R/chemi_alerts_groups_by_id.R')))
  rejected[[1L]]$source <- 'schema/chemi-stdizer-prod.json'
  report <- list(
    toolkit = jsonlite::read_json('dev/specmill-lock.json'),
    baseline_files_compared = length(old),
    changed_baseline_files = as.list(changed),
    second_apply_hashed_files = length(before),
    second_apply_byte_identical = TRUE,
    generation_fresh = TRUE,
    lifecycle_badges_preserved = TRUE,
    repeated_helper_inspection_read_only = TRUE,
    helper_baselines = inspection$helpers,
    manually_adopted_helper_changes = list(),
    stale_adoption_rejected = stale_diagnostic,
    protected_file_retained_independent_output_generated = TRUE,
    protected_contract_conflict_rejected = conflict_diagnostic,
    blocked_contract_diagnostic = rejected[[1L]],
    mixed_selection_apply_rejected_without_writes = conditionMessage(mixed_error),
    independent_supported_generation_after_explicit_scoping = TRUE,
    scope = 'Offline ownership and generation checks. No production requests.'
  )
  jsonlite::write_json(report, 'dev/specmill-pilot/generation-results.json', pretty = TRUE, auto_unbox = TRUE)
})
cat(
  'Only reviewed wrappers differ from baseline; second generation is byte-identical; ownership negative cases pass.\n'
)
