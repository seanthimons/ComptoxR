# All candidate output stays outside package runtime and the root manifest.
out <- 'dev/specmill-rebuild/amos-batch-candidate'
work <- path.expand('~/.cache/comptoxr-specmill-finish/amos-batch-candidate')
lib <- normalizePath('dev/specmill-pilot/artifacts/toolkit-library/0.1.42')
loadNamespace('specmill', lib.loc = lib)
stopifnot(as.character(utils::packageVersion('specmill')) == '0.1.42')
for (directory in c('R', 'schema', 'apis')) {
  dir.create(file.path(work, directory), recursive = TRUE, showWarnings = FALSE)
}
stopifnot(file.copy(file.path(out, 'chemi-amos-reviewed-batch.json'), file.path(work, 'schema'), overwrite = TRUE),
  file.copy(file.path(out, 'service.yml'), file.path(work, 'apis/batch.yml'), overwrite = TRUE),
  all(file.copy(c('R/z_specmill_request.R', 'R/api_validation.R', 'R/service_endpoints.R'), file.path(work, 'R'), overwrite = TRUE)))
writeLines(c('Package: ComptoxR', 'Title: Isolated AMOS batch candidate', 'Version: 3.0.0',
  'Authors@R: person("Sean", "Thimons", email="seanthimons@outlook.com", role=c("aut", "cre"))',
  'Description: Candidate only, not adopted into ComptoxR.', 'License: MIT', 'Encoding: UTF-8',
  'Imports: httr2, jsonlite, cli, curl, lifecycle'), file.path(work, 'DESCRIPTION'))
yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR',
  formatter = list(name = 'air', version = '0.11.0'), services = list('apis/batch.yml')),
  file.path(work, 'specmill.yml'))
callbacks <- new.env(parent = baseenv())
sys.source(file.path(out, 'callbacks.R'), callbacks)
args <- list(root = work, config = 'specmill.yml', callbacks = callbacks,
  validation = TRUE, artifacts = c('wrappers', 'documentation'))
applied <- do.call(specmill::generate_client, c(args, list(mode = 'apply')))
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
stopifnot(length(fresh$operations) == 2L, !length(fresh$diagnostics),
  !length(fresh$mapping_diagnostics), !length(fresh$retained_diagnostics), !length(fresh$drift),
  all(vapply(fresh$validation, function(x) identical(x$status, 'passed'), TRUE)),
  all(vapply(fresh$files, function(x) identical(x$action, 'unchanged'), TRUE)))
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))$files
for (file in names(manifest)) {
  stopifnot(identical(specmill:::output_hash(file.path(work, file)), manifest[[file]]$hash))
}
for (name in c('chemi_amos_batch', 'chemi_amos_analytical_qc_batch')) {
  for (file in c(paste0('R/', name, '.R'), paste0('man/', name, '.Rd'))) {
    stopifnot(file.copy(file.path(work, file), file.path(out, paste0(basename(file), '.txt')), overwrite = TRUE))
  }
}
saveRDS(list(applied = applied, fresh = fresh), file.path(out, 'generation.rds'))
jsonlite::write_json(list(version = '0.1.42', validation = fresh$validation,
  operations = 2L, owners = length(manifest), freshness = TRUE, root_adoption = FALSE,
  generated_project = work), file.path(out, 'generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS: two validated candidate operations, freshness, all ownership hashes.\n')
