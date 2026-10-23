out <- 'dev/specmill-rebuild/canonical-holds-audit/protocol-paging-recheck'
work <- path.expand('~/.cache/comptoxr-specmill-finish/protocol-search-candidate')
loadNamespace('specmill', lib.loc = normalizePath('dev/specmill-pilot/artifacts/toolkit-library/0.1.42'))
stopifnot(as.character(utils::packageVersion('specmill')) == '0.1.42')
for (directory in c('R', 'schema', 'apis')) dir.create(file.path(work, directory), recursive = TRUE, showWarnings = FALSE)
stopifnot(file.copy(file.path(out, 'chemi-stdizer-reviewed-protocol-search.json'), file.path(work, 'schema'), overwrite = TRUE),
  all(file.copy(c('R/z_specmill_request.R', 'R/api_validation.R', 'R/service_endpoints.R', 'R/api_auth.R', 'R/stdizer_protocol_policy.R'), file.path(work, 'R'), overwrite = TRUE)))
service <- yaml::read_yaml(file.path(out, 'service.yml'))
service$hook_config <- NULL
service$schemas$files <- as.list(service$schemas$files)
service$selection$include <- as.list(service$selection$include)
yaml::write_yaml(service, file.path(work, 'apis/service.yml'))
writeLines(c('Package: ComptoxR', 'Title: Isolated protocol search candidate', 'Version: 3.0.0',
  'Authors@R: person("Sean", "Thimons", email="seanthimons@outlook.com", role=c("aut", "cre"))',
  'Description: Reviewed source candidate.', 'License: MIT', 'Encoding: UTF-8',
  'Imports: httr2, jsonlite, cli, curl, lifecycle'), file.path(work, 'DESCRIPTION'))
yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR',
  formatter = list(name = 'air', version = '0.11.0'), services = list('apis/service.yml')), file.path(work, 'specmill.yml'))
args <- list(root = work, config = 'specmill.yml', validation = TRUE, artifacts = c('wrappers', 'documentation'))
applied <- do.call(specmill::generate_client, c(args, list(mode = 'apply')))
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
stopifnot(length(fresh$operations) == 1L, !length(fresh$diagnostics),
  !length(fresh$mapping_diagnostics), !length(fresh$retained_diagnostics), !length(fresh$drift),
  all(vapply(fresh$validation, function(x) identical(x$status, 'passed'), TRUE)),
  all(vapply(fresh$files, function(x) identical(x$action, 'unchanged'), TRUE)))
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))$files
for (file in names(manifest)) stopifnot(identical(specmill:::output_hash(file.path(work, file)), manifest[[file]]$hash))
for (file in c('R/chemi_stdizer_protocols_by_id_post.R', 'man/chemi_stdizer_protocols_by_id_post.Rd')) {
  stopifnot(file.copy(file.path(work, file), file.path(out, paste0(basename(file), '.txt')), overwrite = TRUE))
}
saveRDS(list(applied = applied, fresh = fresh), file.path(out, 'generation.rds'))
jsonlite::write_json(list(version = '0.1.42', validation = fresh$validation, operations = 1L,
  owners = length(manifest), freshness = TRUE, generated_project = work),
  file.path(out, 'generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS: validated protocol search generation and freshness.\n')
