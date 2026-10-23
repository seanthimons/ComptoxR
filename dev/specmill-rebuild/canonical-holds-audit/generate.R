# Run from the repository root. All outputs stay in the audit/cache directories.
out <- 'dev/specmill-rebuild/canonical-holds-audit'
work <- path.expand('~/.cache/comptoxr-specmill-finish/canonical-holds-candidate')
lib <- '/home/sxthi/Documents/Projects/ComptoxR/dev/specmill-pilot/artifacts/toolkit-library/0.1.42'
loadNamespace('specmill', lib.loc = lib)
desc <- utils::packageDescription('specmill', lib.loc = lib)
stopifnot(desc$Version == '0.1.42',
  desc[['Config/specmill/source-commit']] == 'b17a0856263e0179a164a9673399f221168cda6d',
  desc[['Config/specmill/source-archive-sha256']] == 'dbd15b2509171431f00a193a648f426a02873aee5e16a73de740d30b56792351')
route_root <- path.expand('~/.cache/comptoxr-specmill-finish/canonical-holds-routes')
dir.create(file.path(route_root, 'schema'), recursive = TRUE, showWarnings = FALSE)
route_files <- paste0('schema/chemi-', c('descriptors', 'rdkit'), '-prod.json')
stopifnot(all(file.copy(route_files, file.path(route_root, route_files), overwrite = TRUE)))
route_errors <- list()
for (method in c('GET', 'POST')) {
  key <- paste(method, '/api/descriptors')
  route <- paste('chemi-rdkit-prod.json', method, '/api/rdkit')
  service <- list(id = 'calculation-route-repro', schemas = list(files = as.list(route_files)),
    selection = list(include = list(key)), helper = '.ct_request',
    defaults = list(server = list(resolver = '.ct_server_url', key = 'chemi_burl')),
    operations = setNames(list(list(name = if (method == 'GET') 'chemi_descriptors' else 'chemi_descriptors_bulk',
      routes = list(route))), key))
  yaml::write_yaml(service, file.path(route_root, 'service.yml'))
  yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR', services = list('service.yml')),
    file.path(route_root, 'specmill.yml'))
  error <- tryCatch(specmill::generate_client(route_root, config = 'specmill.yml', mode = 'plan',
    validation = TRUE, artifacts = 'wrappers'), error = identity)
  expected <- paste0('calculation-route-repro: route ', route, ' disagrees with ', key, ' server')
  stopifnot(inherits(error, 'error'), identical(conditionMessage(error), expected))
  route_errors[[key]] <- list(message = expected, service = service)
}
jsonlite::write_json(list(version = desc$Version, source_commit = desc[['Config/specmill/source-commit']],
  results = route_errors), file.path(out, 'descriptor-blockers.json'), pretty = TRUE, auto_unbox = TRUE)
for (dir in c('R', 'schema', 'apis')) dir.create(file.path(work, dir), recursive = TRUE, showWarnings = FALSE)
stopifnot(file.copy(file.path(out, 'preflight.yml'), file.path(work, 'apis/preflight.yml'), overwrite = TRUE),
  file.copy(file.path(out, 'chemi-stdizer-reviewed-preflight.json'), file.path(work, 'schema'), overwrite = TRUE),
  all(file.copy(c('R/z_specmill_request.R', 'R/service_endpoints.R'), file.path(work, 'R'), overwrite = TRUE)))
scaffold <- specmill:::request_helper_scaffold('.ct_request', 'https://example.invalid', NULL,
  'COMPTOXR_NATIVE_DRY_RUN', companions = c('batching', 'pagination'))
helper <- gsub("#' @export", "#' @noRd", scaffold$code, fixed = TRUE)
helper <- sub('[ \t]+$', '', strsplit(helper, '\n', fixed = TRUE)[[1L]])
stopifnot(identical(readLines('R/z_specmill_request.R'), helper))
writeLines(c('Package: ComptoxR', 'Title: Isolated standardizer preflight candidate',
  'Version: 3.0.0', 'Authors@R: person("Sean", "Thimons", email="seanthimons@outlook.com", role=c("aut", "cre"))',
  'Description: Review candidate only, not adopted into ComptoxR.', 'License: MIT',
  'Encoding: UTF-8', 'Roxygen: list(markdown = TRUE)', 'Imports: httr2, jsonlite, curl, lifecycle'),
  file.path(work, 'DESCRIPTION'))
writeLines(c('config_version: 1', 'package: ComptoxR', 'formatter:', '  name: air',
  '  version: 0.11.0', 'services:', '- apis/preflight.yml'), file.path(work, 'specmill.yml'))
args <- list(root = work, config = 'specmill.yml', validation = TRUE,
  artifacts = c('wrappers', 'documentation'))
plan <- do.call(specmill::generate_client, c(args, list(mode = 'plan')))
stopifnot(length(plan$operations) == 1L, !length(plan$diagnostics),
  !length(plan$mapping_diagnostics), !length(plan$retained_diagnostics), !length(plan$drift))
do.call(specmill::generate_client, c(args, list(mode = 'apply')))
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
stopifnot(all(vapply(fresh$files, function(x) x$action == 'unchanged', TRUE)))
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
for (file in names(manifest$files)) {
  hash <- digest::digest(paste(readLines(file.path(work, file), warn = FALSE), collapse = '\n'),
    algo = 'sha256', serialize = FALSE)
  stopifnot(identical(hash, manifest$files[[file]]$hash))
}
for (file in c('R/chemi_stdizer_groups_preflight_post.R', 'man/chemi_stdizer_groups_preflight_post.Rd')) {
  stopifnot(file.copy(file.path(work, file), file.path(out, paste0(basename(file), '.txt')), overwrite = TRUE))
}
jsonlite::write_json(list(version = desc$Version, source_commit = desc[['Config/specmill/source-commit']],
  validation_requested = TRUE, validation = fresh$validation, operations = 1L,
  owners = manifest$files, freshness = TRUE, helper_matches_official_scaffold = TRUE,
  root_runtime_adopted = FALSE, generated_project = work),
  file.path(out, 'generation-proof.json'), pretty = TRUE, auto_unbox = TRUE)
cat('Validated generation, freshness and all isolated ownership hashes pass.\n')
