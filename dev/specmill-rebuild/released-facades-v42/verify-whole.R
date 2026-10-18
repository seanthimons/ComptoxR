# Run inside the disposable copy prepared by prepare-whole.py.
stopifnot(file.exists('.facades-private-copy'))
source('dev/specmill-rebuild/released-facades-v42/setup.R')
sys.source('dev/specmill-rebuild/remaining-facades/callbacks.R', callbacks)
args <- list(root = '.', config = 'specmill.yml', callbacks = callbacks,
  artifacts = c('wrappers', 'tests'), validation = TRUE)
p <- do.call(specmill::generate_client, c(args, list(mode = 'apply')))
print(p)
stopifnot(!length(p$diagnostics), !length(p$mapping_diagnostics), !length(p$retained_diagnostics), !length(p$drift))
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
print(fresh)
stopifnot(!length(fresh$diagnostics), !length(fresh$mapping_diagnostics), !length(fresh$retained_diagnostics), !length(fresh$drift),
  all(vapply(fresh$files, function(file) identical(file$action, 'unchanged'), FALSE)))
manifest <- jsonlite::read_json('.specmill/manifest.json')
bad <- names(manifest$files)[!vapply(names(manifest$files), function(path)
  file.exists(path) && identical(specmill:::output_hash(path), manifest$files[[path]]$hash), FALSE)]
stopifnot(!length(bad))
saveRDS(list(generation = p, freshness = fresh, manifest = manifest), file.path(folder, 'whole-client.rds'))
cat('PASS whole-client freshness and', length(manifest$files), 'private owner hashes.\n')
