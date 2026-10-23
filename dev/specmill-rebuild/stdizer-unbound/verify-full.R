# Validate the whole client without writing the parent-owned root manifest.
source('dev/install_specmill.R')
verify_specmill()
work <- file.path(path.expand('~/.cache'), 'comptoxr-stdizer-unbound', 'whole-client')
dir.create(work, recursive = TRUE, showWarnings = FALSE)
for (directory in c('R', 'apis', 'schema', 'inst', 'tests', 'man', 'data', 'dev', '.specmill')) {
  target <- file.path(work, directory)
  if (dir.exists(target)) unlink(target, recursive = TRUE)
  stopifnot(file.copy(directory, work, recursive = TRUE))
}
stopifnot(file.copy(c('DESCRIPTION', 'NAMESPACE', 'specmill.yml', 'air.toml'), work, overwrite = TRUE))
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
scoped <- jsonlite::read_json('dev/specmill-rebuild/stdizer-unbound/ownership.json')
# The isolated NAMESPACE contains only this service's exports. The root exports are checked by the registered suite.
for (file in setdiff(names(scoped$files), 'NAMESPACE')) {
  stopifnot(identical(specmill:::output_hash(file), scoped$files[[file]]$hash))
  # Preserve existing owners, including the shared generated validator.
  if (!is.null(manifest$files[[file]])) {
    stopifnot(identical(manifest$files[[file]]$hash, scoped$files[[file]]$hash))
  } else manifest$files[[file]] <- scoped$files[[file]]
}
jsonlite::write_json(manifest, file.path(work, '.specmill/manifest.json'), auto_unbox = TRUE, pretty = TRUE)
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
args <- list(root = work, config = 'specmill.yml', callbacks = callbacks,
  artifacts = c('wrappers', 'tests'), validation = TRUE)
plan <- do.call(specmill::generate_client, c(args, list(mode = 'apply')))
cat('Official full-client apply complete; checking freshness.\n')
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
stopifnot(!length(fresh$diagnostics), !length(fresh$mapping_diagnostics),
  !length(fresh$retained_diagnostics), !length(fresh$drift),
  all(vapply(fresh$files, `[[`, '', 'action') == 'unchanged'))
owned <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))$files
for (file in names(owned)) {
  stopifnot(identical(specmill:::output_hash(file.path(work, file)), owned[[file]]$hash),
    identical(specmill:::output_hash(file), owned[[file]]$hash))
}
saveRDS(list(generation = plan, freshness = fresh, owners = owned),
  'dev/specmill-rebuild/stdizer-unbound/whole-client.rds')
jsonlite::write_json(list(validation = lapply(fresh$validation, function(report) report[setdiff(names(report), 'operations')]),
  files = length(fresh$files),
  ownership_hashes_checked = length(owned), unchanged = TRUE, diagnostics = fresh$diagnostics,
  mapping_diagnostics = fresh$mapping_diagnostics, retained_diagnostics = fresh$retained_diagnostics,
  drift = fresh$drift), 'dev/specmill-rebuild/stdizer-unbound/whole-client-proof.json',
  auto_unbox = TRUE, pretty = TRUE)
cat('Whole-client validation, freshness and every ownership hash passed.\n')
