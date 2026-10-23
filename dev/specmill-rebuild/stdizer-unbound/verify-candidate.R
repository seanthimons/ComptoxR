# Reproduce source blockers without deploying mutations or changing root ownership.
source('dev/install_specmill.R')
verify_specmill()
work <- file.path(path.expand('~/.cache'), 'comptoxr-stdizer-unbound', 'candidate')
for (directory in c('R', 'apis', 'schema', 'inst')) dir.create(file.path(work, directory), recursive = TRUE, showWarnings = FALSE)
stopifnot(file.copy('dev/specmill-rebuild/stdizer-unbound/candidate-22.yml', file.path(work, 'apis/candidate.yml'), overwrite = TRUE))
for (file in c('schema/chemi-stdizer-prod.json', 'R/z_specmill_request.R', 'R/service_endpoints.R', 'DESCRIPTION')) {
  stopifnot(file.copy(file, file.path(work, file), overwrite = TRUE))
}
writeLines('{}', file.path(work, 'inst/hook_config.yml'))
writeLines(c('config_version: 1', 'package: ComptoxR', 'formatter:', '  name: air',
  '  version: 0.11.0', 'services:', '- apis/candidate.yml'), file.path(work, 'specmill.yml'))
plan <- specmill::generate_client(root = work, config = 'specmill.yml', mode = 'plan',
  validation = TRUE, artifacts = c('wrappers', 'documentation'))
expected <- c('POST /api/stdizer/groups/preflight', 'POST /api/stdizer/groups/{id}/add',
  'POST /api/stdizer/groups/{id}/replace', 'GET /api/stdizer/protocols/{id}',
  'POST /api/stdizer/protocols/{id}')
stopifnot(setequal(vapply(plan$diagnostics, `[[`, '', 'key'), expected),
  !length(plan$mapping_diagnostics), length(plan$operations) == 17L)
print(plan)
saveRDS(plan, 'dev/specmill-rebuild/stdizer-unbound/discovery.rds')
