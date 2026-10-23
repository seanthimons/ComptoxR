# Run from the package root with TMPDIR under persistent storage.
source('dev/install_specmill.R')
verify_specmill()
source('dev/specmill-342/emit.R')
emit_issue342(mode = 'check')
work <- file.path(path.expand('~/.cache'), 'comptoxr-stdizer-unbound', 'generated')
for (directory in c('R', 'apis', 'schema', 'inst')) {
  dir.create(file.path(work, directory), recursive = TRUE, showWarnings = FALSE)
}
config <- yaml::read_yaml('apis/chemi-stdizer-unbound.yml')
for (file in c('apis/chemi-stdizer-unbound.yml', config$schemas$files,
  'R/z_specmill_request.R', 'R/service_endpoints.R', 'DESCRIPTION', 'inst/hook_config.yml', 'air.toml')) {
  stopifnot(file.copy(file, file.path(work, file), overwrite = TRUE))
}
project <- yaml::read_yaml('specmill.yml')
project$services <- list('apis/chemi-stdizer-unbound.yml')
project$callback_files <- NULL
yaml::write_yaml(project, file.path(work, 'specmill.yml'))
args <- list(root = work, config = 'specmill.yml', validation = TRUE,
  artifacts = c('wrappers', 'documentation'))
plan <- do.call(specmill::generate_client, c(args, list(mode = 'apply')))
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
stopifnot(length(fresh$operations) == 15L, !length(fresh$diagnostics),
  !length(fresh$mapping_diagnostics), !length(fresh$retained_diagnostics),
  !length(fresh$drift), all(vapply(fresh$files, `[[`, '', 'action') == 'unchanged'))
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
for (file in names(manifest$files)) {
  stopifnot(identical(specmill:::output_hash(file.path(work, file)), manifest$files[[file]]$hash))
}
# The root manifest is parent-owned. Retain this generator's ownership separately.
stopifnot(file.copy(file.path(work, 'NAMESPACE'), 'dev/specmill-rebuild/stdizer-unbound/isolated-NAMESPACE.txt', overwrite = TRUE))
jsonlite::write_json(manifest, 'dev/specmill-rebuild/stdizer-unbound/ownership.json',
  auto_unbox = TRUE, pretty = TRUE)
for (operation in config$operations) for (file in c(operation$file, paste0('man/', operation$name, '.Rd'))) {
  stopifnot(file.copy(file.path(work, file), file, overwrite = TRUE),
    identical(specmill:::output_hash(file), manifest$files[[file]]$hash))
}
namespace <- readLines('NAMESPACE')
exports <- paste0('export(', vapply(config$operations, `[[`, '', 'name'), ')')
writeLines(c(namespace, setdiff(exports, namespace)), 'NAMESPACE')
invisible(parseNamespaceFile(basename(getwd()), dirname(getwd()), mustExist = TRUE))
saveRDS(list(generation = plan, freshness = fresh),
  'dev/specmill-rebuild/stdizer-unbound/generation.rds')
cat('Validated 15 bindings, fresh output and every isolated ownership hash.\n')
