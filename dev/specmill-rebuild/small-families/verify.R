# Run after prepare.R with the same persistent TMPDIR.
source('dev/install_specmill.R')
verify_specmill()
source('dev/specmill-342/emit.R')
emit_issue342(mode = 'check')
root <- path.expand('~/.cache/comptoxr-small-families/proof-final')
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
plan <- specmill::generate_client(
  root = root,
  config = 'specmill.yml',
  callbacks = callbacks,
  mode = 'check',
  artifacts = c('wrappers', 'tests'),
  validation = TRUE
)
print(plan)
stopifnot(
  !length(plan$diagnostics),
  !length(plan$mapping_diagnostics),
  !length(plan$retained_diagnostics),
  !length(plan$drift),
  all(vapply(plan$files, `[[`, '', 'action') == 'unchanged')
)
manifest <- jsonlite::read_json(file.path(root, '.specmill/manifest.json'))$files
stopifnot(all(vapply(
  names(manifest),
  function(path) {
    identical(specmill:::output_hash(file.path(root, path)), manifest[[path]]$hash)
  },
  logical(1)
)))
parent <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(identical(manifest[names(parent)], parent))
stopifnot(all(vapply(
  names(parent),
  function(path) {
    identical(specmill:::output_hash(path), parent[[path]]$hash)
  },
  logical(1)
)))
frozen <- jsonlite::read_json('dev/specmill-rebuild/small-families/frozen-inputs.json')
stopifnot(all(vapply(
  names(frozen),
  function(path) {
    identical(digest::digest(file = path, algo = 'sha256'), frozen[[path]])
  },
  logical(1)
)))
service <- yaml::read_yaml('apis/chemi-small-families.yml')
for (schema in service$schemas$files) {
  stopifnot(identical(plan$validation[[normalizePath(file.path(root, schema))]]$status, 'passed'))
}
hooks <- yaml::read_yaml('inst/hook_config.yml')
outputs <- lapply(names(service$operations), function(key) {
  operation <- service$operations[[key]]
  paths <- c(operation$file, paste0('man/', operation$name, '.Rd'))
  stopifnot(identical(hooks[[operation$name]]$bespoke_test, 'tests/testthat/test-native_small_families.R'))
  for (path in paths) {
    stopifnot(identical(
      readBin(path, 'raw', file.info(path)$size),
      readBin(file.path(root, path), 'raw', file.info(file.path(root, path))$size)
    ))
  }
  record <- manifest[[operation$file]]
  stopifnot(paste(service$id, key) %in% record$operations)
  list(
    operation = key,
    name = operation$name,
    ownership = record,
    documentation_sha256 = digest::digest(file = paths[[2]], algo = 'sha256')
  )
})
pkgload::load_all(quiet = TRUE)
original <- readRDS('dev/specmill-rebuild/small-families/original-formals.rds')
for (name in names(original)) {
  fn <- getExportedValue('ComptoxR', name)
  stopifnot(identical(if (is.function(fn)) formals(fn) else NULL, original[[name]]))
}
stopifnot(setequal(getNamespaceExports('ComptoxR'), c(names(original), vapply(service$operations, `[[`, '', 'name'))))
source('dev/generate_tests.R')
generate_tests_main('--check')
applied <- readRDS(path.expand('~/.cache/comptoxr-small-families/plan.rds'))
jsonlite::write_json(
  list(
    apply_actions = as.list(table(vapply(applied$files, `[[`, '', 'action'))),
    diagnostics = length(plan$diagnostics),
    mapping_diagnostics = length(plan$mapping_diagnostics),
    retained_diagnostics = length(plan$retained_diagnostics),
    drift = length(plan$drift),
    pin = jsonlite::read_json('dev/specmill-lock.json'),
    full_validation = TRUE,
    freshness = 'passed',
    all_proof_owner_hashes = length(manifest),
    all_parent_owner_hashes = length(parent),
    frozen_file_hashes = length(frozen),
    original_public_exports_checked = length(original),
    outputs = outputs,
    parent_config_and_manifest = 'unchanged; integrate service with official generation in parent'
  ),
  'dev/specmill-rebuild/small-families/verification.json',
  pretty = TRUE,
  auto_unbox = TRUE
)
