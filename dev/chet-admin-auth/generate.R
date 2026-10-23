# Run from the repository root with a persistent TMPDIR set before R starts.
lib <- Sys.getenv('SPECMILL_V41_LIBRARY', '/tmp/chet-specmill41-library')
loadNamespace('specmill', lib.loc = lib)
chet_tool_description <- utils::packageDescription('specmill', lib.loc = lib)
stopifnot(chet_tool_description$Version == '0.1.41',
  chet_tool_description[['Config/specmill/source-commit']] == '05862bee1804806cea157ff1962300d741516301',
  chet_tool_description[['Config/specmill/source-archive-sha256']] == '70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc')
chet_tool_provenance <- list(version = chet_tool_description$Version, commit = chet_tool_description[['Config/specmill/source-commit']], archive = chet_tool_description[['Config/specmill/source-archive-sha256']])
stopifnot(identical(chet_tool_provenance$archive, '70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc'))
# Use the same released scaffold and documentation-only adoption as the parent.
scaffold <- specmill:::request_helper_scaffold('.ct_request', 'https://example.invalid', NULL,
  'COMPTOXR_NATIVE_DRY_RUN', companions = c('batching', 'pagination'))
helper <- gsub("#' @export", "#' @noRd", scaffold$code, fixed = TRUE)
helper <- sub('[ \t]+$', '', strsplit(helper, '\n', fixed = TRUE)[[1L]])
stopifnot(identical(readLines('R/z_specmill_request.R'), helper))
work <- Sys.getenv('CHET_ADMIN_AUTH_STAGE', file.path(path.expand('~/.cache'), 'comptoxr-chet-admin-auth', 'project14'))
dir.create(file.path(work, 'R'), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(work, 'apis'), showWarnings = FALSE)
dir.create(file.path(work, 'schema'), showWarnings = FALSE)
file.copy('apis/chemi-chet-admin-auth.yml', file.path(work, 'apis'), overwrite = TRUE)
config <- yaml::read_yaml('apis/chemi-chet-admin-auth.yml')
for (file in config$schemas$files) {
  stopifnot(file.copy(file, file.path(work, file), overwrite = TRUE))
  stopifnot(identical(digest::digest(file = file, algo = 'sha256'),
    digest::digest(file = file.path(work, file), algo = 'sha256')))
}
# Only the existing transport and resolver definitions are needed for this client.
file.copy(c('R/z_specmill_request.R', 'R/service_endpoints.R'), file.path(work, 'R'), overwrite = TRUE)
writeLines(c('Package: ComptoxR', 'Title: CheT admin/auth binding generation proof',
  'Version: 3.0.0', 'Authors@R: person("Sean", "Thimons", email="seanthimons@outlook.com", role=c("aut", "cre"))',
  'Description: Isolated generation proof for native CheT admin/auth bindings.',
  'License: MIT', 'Encoding: UTF-8', 'Roxygen: list(markdown = TRUE)',
  'Imports: httr2, jsonlite, curl, lifecycle'), file.path(work, 'DESCRIPTION'))
writeLines(c('config_version: 1', 'package: ComptoxR', 'formatter:', '  name: air',
  '  version: 0.11.0', 'services:', '- apis/chemi-chet-admin-auth.yml'), file.path(work, 'specmill.yml'))
args <- list(root = work, config = 'specmill.yml', validation = TRUE,
  artifacts = c('wrappers', 'documentation'))
plan <- do.call(specmill::generate_client, c(args, list(mode = 'plan')))
stopifnot(length(plan$operations) == 14L, !length(plan$diagnostics),
  !length(plan$mapping_diagnostics), !length(plan$drift), !length(plan$retained_diagnostics))
cat('Validated plan:', length(plan$operations), 'operations\n')
applied <- do.call(specmill::generate_client, c(args, list(mode = 'apply')))
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
for (file in names(manifest$files)) {
  stopifnot(identical(digest::digest(paste(readLines(file.path(work, file), warn = FALSE), collapse = '\n'), algo = 'sha256', serialize = FALSE), manifest$files[[file]]$hash))
}
files <- vapply(config$operations, `[[`, '', 'file')
for (file in files) stopifnot(file.copy(file.path(work, file), file, overwrite = TRUE))
for (op in config$operations) {
  file <- paste0('man/', op$name, '.Rd')
  stopifnot(file.copy(file.path(work, file), file, overwrite = TRUE))
}
exports <- paste0('export(', vapply(config$operations, `[[`, '', 'name'), ')')
namespace <- readLines('NAMESPACE')
writeLines(c(namespace, setdiff(exports, namespace)), 'NAMESPACE')
validation <- fresh$validation
names(validation) <- sub(paste0(work, '/'), '', names(validation), fixed = TRUE)
for (name in names(validation)) validation[[name]]$source <- name
proof <- list(version = chet_tool_provenance$version, source_commit = chet_tool_provenance$commit,
  archive_sha256 = chet_tool_provenance$archive, validation = validation,
  helper_matches_v41_scaffold = TRUE,
  helper_sha256 = digest::digest(file = 'R/z_specmill_request.R', algo = 'sha256'),
  validator_matches_worktree = identical(readLines('R/api_validation.R'), readLines(file.path(work, 'R/api_validation.R'))),
  operations = length(fresh$operations), owners = manifest$files,
  fresh = all(vapply(fresh$files, function(x) x$action %in% c('unchanged', 'retained'), TRUE)),
  source_sha256 = lapply(stats::setNames(config$schemas$files, config$schemas$files),
    function(file) digest::digest(file = file, algo = 'sha256')))
jsonlite::write_json(proof, 'dev/chet-admin-auth/generation-proof.json', auto_unbox = TRUE, pretty = TRUE)
cat('Validated generation, freshness and every manifest file hash passed for 14 bindings.\n')
