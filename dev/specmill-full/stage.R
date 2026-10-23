# Render the reviewed whole-client candidates into an isolated package copy.
source('dev/install_specmill.R')
verify_specmill()
records <- readRDS('dev/specmill-pilot/artifacts/full-proposal/records.rds')
candidates <- Filter(function(x) x$status == 'candidate', records)
stage <- 'dev/specmill-pilot/artifacts/full-client'
if (dir.exists(stage)) {
  stop('Stage already exists; inspect it before creating another proposal')
}
dir.create(stage, recursive = TRUE)
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
  'air.toml',
  '.Rbuildignore'
)
stopifnot(all(file.copy(inputs, stage, recursive = TRUE)))
dir.create(file.path(stage, 'dev'))
stopifnot(file.copy('dev/specmill_callbacks.R', file.path(stage, 'dev')))
contracts <- cases <- hashes <- list()
Sys.setenv(batch_limit = '2')
for (name in names(candidates)) {
  record <- candidates[[name]]
  original <- eval(record$original, envir = new.env(parent = baseenv()))
  required <- names(Filter(function(x) isTRUE(x$required), record$proposal$inputs))
  supplied <- setNames(as.list(rep('pilot-1', length(required))), required)
  calls <- list()
  helper <- record$proposal$helper
  assign(
    helper,
    function(...) {
      calls[[length(calls) + 1L]] <<- list(
        helper = helper,
        arguments = list(...),
        response = list(list(id = 'pilot-response'))
      )
      list(list(id = 'pilot-response'))
    },
    envir = environment(original)
  )
  result <- do.call(original, supplied)
  stopifnot(length(calls) == 1L)
  contracts[[name]] <- list(inputs = supplied, calls = calls, result = result, environment = list(batch_limit = '2'))
  cases[[name]] <- list(
    schema = record$schema,
    key = record$key,
    inputs = supplied,
    arguments = calls[[1L]]$arguments,
    helper = helper,
    required = as.list(required)
  )
  text <- paste(readLines(record$file, warn = FALSE), collapse = '\n')
  baseline <- paste(
    readLines(file.path('dev/specmill-pilot/artifacts/before-source', record$file), warn = FALSE),
    collapse = '\n'
  )
  stopifnot(identical(text, baseline))
  hashes[[record$file]] <- digest::digest(enc2utf8(text), algo = 'sha256', serialize = FALSE)
  # Compare the rendered function's helper boundary with the original before staging.
  env <- new.env(parent = environment(original))
  eval(parse(text = record$rendered), env)
  calls <- list()
  stopifnot(identical(do.call(env[[name]], supplied), result), identical(calls, contracts[[name]]$calls))
}
saveRDS(contracts, file.path(stage, 'tests/testthat/fixtures/specmill-full-contracts.rds'), version = 3)
saveRDS(cases, 'dev/specmill-full/runtime-cases.rds', version = 3)
jsonlite::write_json(hashes, 'dev/specmill-full/adoption-hashes.json', pretty = TRUE, auto_unbox = TRUE)
project <- yaml::read_yaml('specmill.yml')
project$callback_files <- as.list(project$callback_files)
project$services <- as.list(project$services)
for (schema in unique(vapply(candidates, `[[`, '', 'schema'))) {
  selected <- Filter(function(x) identical(x$schema, schema), candidates)
  service <- list(
    id = sub('[.]json$', '-full', schema),
    schemas = list(files = list(file.path('schema', schema))),
    selection = list(include = unname(lapply(selected, `[[`, 'key'))),
    helper = 'generic_request',
    documentation = TRUE,
    operations = setNames(lapply(selected, `[[`, 'proposal'), vapply(selected, `[[`, '', 'key')),
    contracts_file = 'tests/testthat/fixtures/specmill-full-contracts.rds'
  )
  path <- file.path('apis', paste0(service$id, '.yml'))
  yaml::write_yaml(service, file.path(stage, path))
  project$services <- c(project$services, list(path))
}
yaml::write_yaml(project, file.path(stage, 'specmill.yml'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
plan <- specmill::generate_client(
  stage,
  config = 'specmill.yml',
  callbacks = callbacks,
  mode = 'plan',
  artifacts = c('wrappers', 'tests'),
  adopt = hashes
)
print(plan)
stopifnot(
  length(plan$diagnostics) == 0L,
  length(plan$mapping_diagnostics) == 0L,
  length(plan$retained_diagnostics) == 0L,
  length(plan$drift) == 0L,
  !any(vapply(plan$files, function(x) x$action == 'protected', FALSE))
)
specmill::generate_client(
  stage,
  config = 'specmill.yml',
  callbacks = callbacks,
  mode = 'apply',
  artifacts = c('wrappers', 'tests'),
  adopt = hashes
)
cat('Staged', length(candidates), 'candidates in', stage, '\n')
