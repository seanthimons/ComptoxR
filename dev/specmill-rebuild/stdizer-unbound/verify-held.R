source('dev/install_specmill.R')
verify_specmill()
work <- file.path(path.expand('~/.cache'), 'comptoxr-stdizer-unbound', 'held')
for (directory in c('R', 'apis', 'schema', 'inst')) dir.create(file.path(work, directory), recursive = TRUE, showWarnings = FALSE)
file.copy('dev/specmill-rebuild/stdizer-unbound/held-freeze.yml', file.path(work, 'apis/freeze.yml'), overwrite = TRUE)
for (file in c('schema/chemi-stdizer-prod.json', 'R/z_specmill_request.R', 'R/service_endpoints.R', 'DESCRIPTION')) {
  stopifnot(file.copy(file, file.path(work, file), overwrite = TRUE))
}
writeLines('{}', file.path(work, 'inst/hook_config.yml'))
writeLines(c('config_version: 1', 'package: ComptoxR', 'formatter:', '  name: air',
  '  version: 0.11.0', 'services:', '- apis/freeze.yml'), file.path(work, 'specmill.yml'))
plan <- specmill::generate_client(root = work, config = 'specmill.yml', mode = 'apply',
  validation = TRUE, artifacts = 'wrappers')
stopifnot(!length(plan$diagnostics), length(plan$operations) == 1L)
environment <- new.env(parent = baseenv())
sys.source('R/z_specmill_request.R', environment)
sys.source(file.path(work, 'R/api_validation.R'), environment)
sys.source('R/service_endpoints.R', environment)
sys.source(file.path(work, 'R/chemi_stdizer_groups_by_id_freeze_patch.R'), environment)
directory <- tempfile('freeze-')
dir.create(directory)
server <- callr::r_bg(function(directory) {
  port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1', port, list(call = function(req) {
    saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, query = req$QUERY_STRING), file.path(directory, 'wire.rds'))
    list(status = 200L, headers = list(`Content-Type` = 'application/json'), body = '{}')
  }))
  saveRDS(port, file.path(directory, 'ready.rds'))
  repeat httpuv::service(50)
}, args = list(directory), supervise = TRUE)
tryCatch({
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  stopifnot(file.exists(file.path(directory, 'ready.rds')))
  options(ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))))
  environment$chemi_stdizer_groups_by_id_freeze_patch('group-123', freeze = FALSE, hierarchically = TRUE)
  wire <- readRDS(file.path(directory, 'wire.rds'))
  stopifnot(identical(wire$method, 'PATCH'), identical(wire$path, '/api/stdizer/groups/group-123/freeze'),
    grepl('freeze=FALSE', wire$query, fixed = TRUE), grepl('hierarchically=TRUE', wire$query, fixed = TRUE))
  jsonlite::write_json(list(issue = 'https://github.com/seanthimons/specmill/issues/177',
    wire = wire, expected_query = 'freeze=false&hierarchically=true',
    localhost_only = TRUE, validation = plan$validation),
    'dev/specmill-rebuild/stdizer-unbound/held-freeze-proof.json', auto_unbox = TRUE, pretty = TRUE)
}, finally = { server$kill(); unlink(directory, recursive = TRUE) })
