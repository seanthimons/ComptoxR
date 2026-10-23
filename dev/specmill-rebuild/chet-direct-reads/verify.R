# Full validated freshness check plus independent source/test ownership checks.
source('dev/install_specmill.R')
verify_specmill()
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
plan <- specmill::generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'check', artifacts = c('wrappers', 'tests'), validation = TRUE)
print(plan)
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$drift),
  !length(plan$retained_diagnostics))
service <- yaml::read_yaml('apis/chemi-chet-direct-reads.yml')
manifest <- jsonlite::read_json('.specmill/manifest.json')$files
hooks <- yaml::read_yaml('inst/hook_config.yml')
stopifnot(length(service$operations) == 4L,
  identical(plan$validation[[normalizePath('schema/chemi-chet-prod.json')]]$status, 'passed'))
outputs <- lapply(names(service$operations), function(key) {
  operation <- service$operations[[key]]
  record <- manifest[[operation$file]]
  hash <- digest::digest(enc2utf8(gsub('\r\n?', '\n', paste(readLines(operation$file), collapse = '\n'))),
    algo = 'sha256', serialize = FALSE)
  stopifnot(identical(record$hash, hash), paste(service$id, key) %in% record$operations,
    identical(hooks[[operation$name]]$bespoke_test, 'tests/testthat/test-native_chet_direct_reads.R'),
    file.exists(paste0('man/', operation$name, '.Rd')))
  list(operation = key, wrapper = operation$name, file = operation$file, sha256 = hash)
})
docs <- unname(c('NAMESPACE', vapply(service$operations, function(x) paste0('man/', x$name, '.Rd'), '')))
before <- vapply(docs, function(path) digest::digest(file = path, algo = 'sha256'), '')
stage <- tempfile('chet-docs-'); dir.create(stage)
for (path in c('DESCRIPTION', 'NAMESPACE', 'LICENSE', 'R', 'man', 'inst', 'data')) {
  if (file.exists(path)) stopifnot(file.copy(path, stage, recursive = TRUE))
}
roxygen2::roxygenise(stage, roclets = c('rd', 'namespace'))
stopifnot(identical(before, vapply(docs, function(path) digest::digest(file = file.path(stage, path), algo = 'sha256'), '')))
unlink(stage, recursive = TRUE)
jsonlite::write_json(list(documentation_freshness = 'passed', documentation_sha256 = as.list(before), toolkit = jsonlite::read_json('dev/specmill-lock.json'),
  schema_sha256 = digest::digest(file = 'schema/chemi-chet-prod.json', algo = 'sha256'),
  validation = TRUE, schema_status = 'passed', freshness = 'passed', endpoint_count = length(outputs),
  outputs = outputs), 'dev/specmill-rebuild/chet-direct-reads/verification.json', pretty = TRUE, auto_unbox = TRUE)
