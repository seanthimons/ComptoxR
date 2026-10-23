# Build the whole parent client plus this wave without changing shared ownership.
source('dev/install_specmill.R')
verify_specmill()
root <- path.expand('~/.cache/comptoxr-small-families/proof-final')
if (dir.exists(root)) {
  unlink(root, recursive = TRUE)
}
dir.create(root, recursive = TRUE, showWarnings = FALSE)
for (path in c(
  'air.toml',
  'DESCRIPTION',
  'NAMESPACE',
  'LICENSE',
  'R',
  'man',
  'inst',
  'apis',
  'schema',
  'tests',
  'data',
  '.specmill',
  'specmill.yml'
)) {
  stopifnot(file.copy(path, root, recursive = TRUE))
}
dir.create(file.path(root, 'dev'), showWarnings = FALSE)
for (path in c(
  'dev/specmill_callbacks.R',
  'dev/specmill-rebuild',
  'dev/specmill-pilot',
  'dev/specmill-full',
  'dev/specmill-342'
)) {
  # Toolkit libraries and other ignored build artifacts are unnecessary.
  if (dir.exists(path) && basename(path) == 'specmill-pilot') {
    dir.create(file.path(root, path), recursive = TRUE, showWarnings = FALSE)
    files <- list.files(path, full.names = TRUE)
    files <- files[basename(files) != 'artifacts']
    stopifnot(all(file.copy(files, file.path(root, path), recursive = TRUE)))
  } else if (file.exists(path)) {
    stopifnot(file.copy(path, file.path(root, 'dev'), recursive = TRUE))
  }
}
cfg <- yaml::read_yaml('specmill.yml')
cfg$services <- as.list(c(cfg$services, 'apis/chemi-small-families.yml'))
cfg$callback_files <- as.list(cfg$callback_files)
yaml::write_yaml(cfg, file.path(root, 'specmill.yml'))
# New outputs have no parent owner; let official generation create them afresh.
service <- yaml::read_yaml('apis/chemi-small-families.yml')
paths <- vapply(service$operations, `[[`, '', 'file')
parent <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(!any(paths %in% names(parent)))
unlink(file.path(root, paths))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
plan <- specmill::generate_client(
  root = root,
  config = 'specmill.yml',
  callbacks = callbacks,
  mode = 'apply',
  artifacts = c('wrappers', 'tests'),
  validation = TRUE
)
print(plan)
saveRDS(plan, path.expand('~/.cache/comptoxr-small-families/plan.rds'))
stopifnot(
  !length(plan$diagnostics),
  !length(plan$mapping_diagnostics),
  !length(plan$retained_diagnostics),
  !length(plan$drift)
)

# Match the parent workflow: documentation is generated separately by roxygen.
roxygen2::roxygenise(root, roclets = c('rd', 'namespace'))
# Documentation and new files are inputs; refresh their provenance officially.
refreshed <- specmill::generate_client(
  root = root,
  config = 'specmill.yml',
  callbacks = callbacks,
  mode = 'apply',
  artifacts = c('wrappers', 'tests'),
  validation = TRUE
)
print(refreshed)
stopifnot(
  !length(refreshed$diagnostics),
  !length(refreshed$mapping_diagnostics),
  !length(refreshed$retained_diagnostics),
  !length(refreshed$drift),
  all(vapply(
    refreshed$files,
    function(x) {
      identical(x$action, 'unchanged') ||
        (identical(x$file, '.specmill/manifest.json') && identical(x$action, 'write'))
    },
    FALSE
  ))
)
saveRDS(refreshed, path.expand('~/.cache/comptoxr-small-families/refresh-plan.rds'))
