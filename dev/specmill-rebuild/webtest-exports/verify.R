# Run after generate.R; all generated ownership is isolated in the proof checkout.
source('dev/install_specmill.R')
verify_specmill('/home/sxthi/Documents/Projects/ComptoxR/dev/specmill-pilot/artifacts/toolkit-library/0.1.42')
root <- path.expand('~/.cache/comptoxr-specmill-finish/proof')
fresh <- readRDS(path.expand('~/.cache/comptoxr-specmill-finish/freshness.rds'))
stopifnot(!length(fresh$diagnostics), !length(fresh$mapping_diagnostics),
  !length(fresh$retained_diagnostics), !length(fresh$drift),
  all(vapply(fresh$files, `[[`, '', 'action') == 'unchanged'),
  all(vapply(fresh$validation, function(x) identical(x$status, 'passed'), FALSE)))
parent <- jsonlite::read_json('.specmill/manifest.json')$files
manifest <- jsonlite::read_json(file.path(root, '.specmill/manifest.json'))$files
stopifnot(identical(manifest[names(parent)], parent))
stopifnot(all(vapply(names(manifest), function(path)
  identical(specmill:::output_hash(file.path(root, path)), manifest[[path]]$hash), FALSE)))
# Every original tracked input/output must still match the fixed parent commit.
paths <- system2('git', c('ls-tree', '-r', '--name-only', '3ea6140c'), stdout = TRUE)
paths <- paths[grepl('^(schema/|R/|apis/|man/|dev/specmill-lock.json$|specmill.yml$|.specmill/manifest.json$)', paths)]
changed <- system2('git', c('diff', '--name-only', '3ea6140c', '--'), stdout = TRUE)
stopifnot(!length(intersect(changed, paths)))
hashes <- lapply(paths, function(path) {
  baseline <- file.path(root, path)
  # Generated outputs retain all original file bytes in this candidate.
  stopifnot(identical(digest::digest(file = path, algo = 'sha256'),
    digest::digest(file = baseline, algo = 'sha256')) || grepl('^man/', path) || path %in% c('specmill.yml', '.specmill/manifest.json'))
  digest::digest(file = path, algo = 'sha256')
})
names(hashes) <- paths
service <- yaml::read_yaml('apis/chemi-webtest-exports.yml')
outputs <- lapply(names(service$operations), function(key) {
  op <- service$operations[[key]]
  for (path in c(op$file, paste0('man/', op$name, '.Rd'))) {
    stopifnot(identical(digest::digest(file = path, algo = 'sha256'),
      digest::digest(file = file.path(root, path), algo = 'sha256')))
  }
  stopifnot(paste(service$id, key) %in% manifest[[op$file]]$operations)
  list(operation = key, name = op$name, ownership = manifest[[op$file]])
})
jsonlite::write_json(list(parent = '3ea6140c', pin = jsonlite::read_json('dev/specmill-lock.json'),
  full_validation = TRUE, freshness = TRUE, validated_schemas = length(fresh$validation),
  canonical_schema_files_unchanged = sum(grepl('^schema/', paths)),
  existing_generation_warning = 'OAS 3.1 GET request body has undefined interoperability semantics',
  parent_owners_unchanged = length(parent), verified_proof_hashes = length(manifest),
  counted_operations = 2L, new_holds = 0L,
  existing_hold = 'chemi-safety-prod.json GET /api/alerts/render, specmill#61',
  outputs = outputs, frozen_hashes = hashes),
  'dev/specmill-rebuild/webtest-exports/verification.json', pretty = TRUE, auto_unbox = TRUE)
