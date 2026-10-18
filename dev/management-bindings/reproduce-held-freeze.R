# Reproduce Specmill #177 with the official, unmodified candidate and localhost.
# Set a persistent TMPDIR before launching R. No public API call is made.
pkgload::load_all('.', quiet = TRUE)
environment <- new.env(parent = asNamespace('ComptoxR'))
sys.source('dev/management-bindings/held-freeze.R', envir = environment)
directory <- tempfile('held-freeze-')
dir.create(directory)
server <- callr::r_bg(function(directory) {
  port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1', port, list(call = function(req) {
    saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO,
      query = req$QUERY_STRING), file.path(directory, 'received.rds'))
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
  withr::with_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(timeout = 5, max_retries = 0L)), {
    environment$chemi_alerts_groups_freeze_by_id('report-123', FALSE, TRUE)
  })
  received <- readRDS(file.path(directory, 'received.rds'))
  stopifnot(identical(received$method, 'PATCH'),
    identical(received$path, '/api/alerts/groups/report-123/freeze'),
    identical(received$query, '?freeze=FALSE&hierarchically=TRUE'))
  jsonlite::write_json(list(issue = 'https://github.com/seanthimons/specmill/issues/177',
    status = 'held', localhost_only = TRUE, received = received,
    expected_query = '?freeze=false&hierarchically=true',
    candidate_sha256 = digest::digest(file = 'dev/management-bindings/held-freeze.R', algo = 'sha256')),
    'dev/management-bindings/held-freeze-proof.json', auto_unbox = TRUE, pretty = TRUE)
}, finally = {
  server$kill()
  unlink(directory, recursive = TRUE)
})
