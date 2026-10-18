# This creates a minimal temporary generator project; it never calls a service.
lib <- Sys.getenv('SPECMILL_LIBRARY')
stopifnot(nzchar(lib), dir.exists(lib))
loadNamespace('specmill', lib.loc = lib)
metadata <- utils::packageDescription('specmill', lib.loc = lib)
stopifnot(identical(metadata$Version, '0.1.41'),
  identical(metadata[['Config/specmill/source-commit']], '05862bee1804806cea157ff1962300d741516301'),
  identical(metadata[['Config/specmill/source-archive-sha256']], '70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc'))
folder <- 'dev/specmill-rebuild/remaining-facades'
root <- tempfile('held-groups-')
dir.create(root)
dir.create(file.path(root, 'R'))
dir.create(file.path(root, 'schema'))
stopifnot(all(file.copy(list.files('R', full.names = TRUE), file.path(root, 'R'))))
for (name in c('stdizer', 'alerts')) {
  stopifnot(file.copy(paste0('schema/chemi-', name, '-prod.json'), file.path(root, 'schema')))
  config <- yaml::read_yaml(file.path(folder, paste0(name, '-held.yml')))
  config$schemas$files <- as.list(config$schemas$files)
  config$selection$include <- as.list(config$selection$include)
  config$documentation <- FALSE
  config$operations[[1L]]$docs <- NULL
  config$operations[[1L]]$defer_inputs <- as.list(config$operations[[1L]]$defer_inputs)
  config$operations[[1L]]$exclude_parameters <- as.list(config$operations[[1L]]$exclude_parameters)
  yaml::write_yaml(config, file.path(root, paste0(name, '.yml')))
}
if (file.exists('air.toml')) stopifnot(file.copy('air.toml', file.path(root, 'air.toml')))
yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR', formatter = yaml::read_yaml('specmill.yml')$formatter, services = list('stdizer.yml', 'alerts.yml')),
  file.path(root, 'specmill.yml'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
sys.source(file.path(folder, 'callbacks.R'), callbacks)
paths <- paste0('R/', list.files(file.path(root, 'R')))
adopt <- lapply(stats::setNames(paths, paths), function(path) specmill:::output_hash(file.path(root, path)))
plan <- specmill::generate_client(root, config = 'specmill.yml', callbacks = callbacks,
  mode = 'apply', artifacts = 'wrappers', validation = TRUE, adopt = adopt)
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$retained_diagnostics), !length(plan$drift))
for (name in c('chemi_stdizer_groups_bulk', 'chemi_alerts_groups_bulk')) {
  generated <- readLines(file.path(root, 'R', paste0(name, '.R')))
  stopifnot(identical(generated, readLines(file.path(folder, 'generated-held', paste0(name, '.R')))))
}
plan <- specmill::generate_client(root, config = 'specmill.yml', callbacks = callbacks,
  mode = 'check', artifacts = 'wrappers', validation = TRUE)
print(plan)
message('Held JSON-only projection proof passed. This establishes no service upload/mutation contract.')
