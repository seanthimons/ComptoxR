out <- 'dev/specmill-rebuild/released-v51'
source('dev/install_specmill.R'); verify_specmill()
stopifnot(as.character(utils::packageVersion('specmill')) == '0.1.51')
source('dev/specmill-342/emit.R'); emit_issue342(mode = 'check')
before <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(length(before) == 715L)
callbacks <- new.env(parent = baseenv())
for (file in yaml::read_yaml('specmill.yml')$callback_files) sys.source(file, envir = callbacks)
applied <- specmill::generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'apply', artifacts = c('wrappers', 'tests'), validation = TRUE)
saveRDS(applied, file.path(out, 'applied.rds'))
stopifnot(all(vapply(applied$validation, function(x) identical(x$status, 'passed'), FALSE)),
  !length(applied$diagnostics), !length(applied$mapping_diagnostics), !length(applied$drift))
after <- jsonlite::read_json('.specmill/manifest.json')$files
changed <- names(before)[!vapply(names(before), function(path) identical(before[[path]], after[[path]]), FALSE)]
stopifnot(length(after) == 715L, identical(changed, 'R/chemi_alerts_render.R'),
  identical(before[[changed]]$hash, after[[changed]]$hash))
actual <- after[[changed]]$response_sources
prior <- jsonlite::read_json(file.path(out, 'prior-v50-response-evidence.json'))
relative <- function(x) {
  x$selected <- paste0('schema/', basename(x$selected))
  x$sources <- lapply(x$sources, function(s) {s$source <- paste0('schema/', basename(s$source)); s})
  x
}
stopifnot(identical(actual, lapply(prior, relative)))
source('dev/generate_specmill.R')
fresh <- generate_specmill('check')
saveRDS(fresh, file.path(out, 'root-fresh.rds'))
stopifnot(all(vapply(names(after), function(p) identical(specmill:::output_hash(p), after[[p]]$hash), FALSE)))
state <- jsonlite::read_json(file.path(out, 'before-state.json'))
for (group in c('core', 'schema_hashes')) {
  hashes <- state[[group]]
  if (!is.null(hashes)) stopifnot(all(vapply(names(hashes), function(p)
    identical(digest::digest(file = p, algo = 'sha256'), hashes[[p]]), FALSE)))
}
jsonlite::write_json(list(version = '0.1.51', owners = length(after), sources = length(fresh$validation),
  validation = TRUE, freshness = TRUE, changed_ownership_record = changed,
  package_core_unchanged = TRUE, canonical_schemas_unchanged = TRUE,
  selected_response_contracts_and_hashes_unchanged = TRUE,
  persisted_response_sources_project_relative = TRUE), file.path(out, 'generation.json'),
  pretty = TRUE, auto_unbox = TRUE)
cat('PASS v51 root generation, metadata-only ownership and freshness.\n')
