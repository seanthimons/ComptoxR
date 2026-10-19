out <- 'dev/specmill-rebuild/released-booleans-v45'
source('dev/install_specmill.R'); verify_specmill()
callbacks <- new.env(parent = baseenv())
for (file in yaml::read_yaml('specmill.yml')$callback_files) sys.source(file, callbacks)
before <- jsonlite::read_json('.specmill/manifest.json')$files
applied <- specmill::generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'apply', artifacts = c('wrappers', 'tests'), validation = TRUE)
saveRDS(applied, file.path(out, 'final-reconcile.rds'))
changes <- Filter(function(file) file$action != 'unchanged', applied$files)
print(changes)
stopifnot(length(changes) == 1L, changes[[1L]]$file == '.specmill/manifest.json',
  changes[[1L]]$action == 'write', !length(applied$diagnostics), !length(applied$mapping_diagnostics),
  !length(applied$drift), all(vapply(applied$validation, function(x) identical(x$status, 'passed'), FALSE)))
after <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(identical(before, after), length(after) == 708L)
source('dev/generate_specmill.R')
fresh <- generate_specmill('check')
saveRDS(fresh, file.path(out, 'final-fresh.rds'))
stopifnot(all(vapply(names(after), function(path) identical(specmill:::output_hash(path), after[[path]]$hash), FALSE)))
jsonlite::write_json(list(owners = length(after), sources = length(fresh$validation),
  freshness = TRUE, reconciliation_only = '.specmill/manifest.json', owner_records_unchanged = TRUE),
  file.path(out, 'final-generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS: final registry/input metadata reconciled; no runtime or owner-record changes; all708 owners and33 sources fresh.\n')
