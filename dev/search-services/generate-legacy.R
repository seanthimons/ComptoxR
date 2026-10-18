loadNamespace('specmill', lib.loc = Sys.getenv('SPECMILL_V41_LIBRARY', '/tmp/chet-specmill41-library'))
desc <- utils::packageDescription('specmill')
stopifnot(desc$Version == '0.1.41', desc[['Config/specmill/source-commit']] == '05862bee1804806cea157ff1962300d741516301')
work <- Sys.getenv('SERVICES_LEGACY_STAGE', path.expand('~/.cache/comptoxr-search-services/legacy-final'))
for (dir in c('R', 'apis', 'schema', '.specmill')) dir.create(file.path(work, dir), recursive = TRUE, showWarnings = FALSE)
config <- yaml::read_yaml('apis/chemi-services-prod-rebuild.yml')
keys <- c('POST /api/services/collated_report', 'POST /api/services/convert')
config$schemas$files <- as.list(config$schemas$files)
config$selection$include <- as.list(keys)
config$operations <- config$operations[keys]
config$contracts_file <- NULL
yaml::write_yaml(config, file.path(work, 'apis/legacy.yml'))
source_files <- c('schema/chemi-services-prod.json', 'R/z_specmill_request.R', 'R/service_endpoints.R',
  'R/chemi_services_inputs.R', 'R/z_generic_request.R')
for (file in source_files) stopifnot(file.copy(file, file.path(work, file), overwrite = TRUE))
old <- jsonlite::read_json('.specmill/manifest.json')
old$files <- jsonlite::read_json('dev/search-services/legacy-before/owners.json')
files <- vapply(config$operations, `[[`, '', 'file')
# Start from the old owned bytes. Never overwrite a desired candidate onto old ownership.
if (!file.exists(file.path(work, '.specmill/manifest.json'))) {
  old$files <- old$files[files]
  for (file in files) {
    frozen <- file.path('dev/search-services/legacy-before', basename(file))
    stopifnot(identical(digest::digest(paste(readLines(frozen), collapse = '\n'), algo = 'sha256', serialize = FALSE), old$files[[file]]$hash))
    stopifnot(file.copy(frozen, file.path(work, file)))
  }
  jsonlite::write_json(old, file.path(work, '.specmill/manifest.json'), auto_unbox = TRUE, pretty = TRUE)
}
writeLines(c('Package: ComptoxR', 'Title: Legacy service binding proof', 'Version: 3.0.0',
  'Authors@R: person("Sean", "Thimons", email="seanthimons@outlook.com", role=c("aut", "cre"))',
  'Description: Isolated validated generation.', 'License: MIT', 'Encoding: UTF-8',
  'Roxygen: list(markdown = TRUE)', 'Imports: httr2, jsonlite, curl, lifecycle'), file.path(work, 'DESCRIPTION'))
writeLines(c('config_version: 1', 'package: ComptoxR', 'formatter:', '  name: air',
  '  version: 0.11.0', 'services:', '- apis/legacy.yml'), file.path(work, 'specmill.yml'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
args <- list(root = work, config = 'specmill.yml', callbacks = callbacks, validation = TRUE,
  artifacts = c('wrappers', 'documentation'))
plan <- do.call(specmill::generate_client, c(args, list(mode = 'plan')))
stopifnot(length(plan$operations) == 2L, !length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$drift), !length(plan$retained_diagnostics))
do.call(specmill::generate_client, c(args, list(mode = 'apply')))
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
for (file in names(manifest$files)) stopifnot(identical(digest::digest(paste(readLines(file.path(work, file)), collapse = '\n'), algo = 'sha256', serialize = FALSE), manifest$files[[file]]$hash))
for (file in c(files, paste0('man/', vapply(config$operations, `[[`, '', 'name'), '.Rd'))) stopifnot(file.copy(file.path(work, file), file, overwrite = TRUE))
validation <- fresh$validation
names(validation) <- sub(paste0(work, '/'), '', names(validation), fixed = TRUE)
for (name in names(validation)) validation[[name]]$source <- name
jsonlite::write_json(list(operations = 2L, version = desc$Version, source_commit = desc[['Config/specmill/source-commit']],
  fresh = all(vapply(fresh$files, function(x) x$action %in% c('unchanged', 'retained'), TRUE)),
  validation = validation, old_owners = old$files[files], owners = manifest$files),
  'dev/search-services/legacy-generation-proof.json', auto_unbox = TRUE, pretty = TRUE)
