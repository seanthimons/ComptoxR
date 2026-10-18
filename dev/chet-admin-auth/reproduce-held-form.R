# Run with persistent TMPDIR. Generated held wrappers are evidence, never exports.
config <- jsonlite::read_json('dev/chet-admin-auth/held.json')
rows <- Filter(function(row) identical(row$upstream, 'https://github.com/seanthimons/specmill/issues/178'), config)
stopifnot(length(rows) == 3L)
pkgload::load_all('.', quiet = TRUE)
directory <- tempfile('held-form-localhost-')
dir.create(directory)
server <- callr::r_bg(function(directory) {
  port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1', port, list(call = function(req) {
    writeLines(req$REQUEST_METHOD, file.path(directory, 'unexpected-http'))
    list(status = 200L, headers = list(`Content-Type` = 'text/plain'), body = 'sentinel')
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
  canonical <- jsonlite::read_json('schema/chemi-chet-prod.json')
  for (row in rows) {
    path <- sub('^[^ ]+ ', '', row$key)
    stopifnot(identical(row$requestBody, canonical$paths[[path]]$post$requestBody),
      isTRUE(row$requestBody$content[['application/x-www-form-urlencoded']]$schema$additionalProperties))
    env <- new.env(parent = asNamespace('ComptoxR'))
    source(file.path('dev/chet-admin-auth/held-generated', paste0(row$name, '.R')), local = env)
    error <- tryCatch(env[[row$name]](body = list(username = 'invented localhost user', password = 'invented localhost password')), error = identity)
    stopifnot(inherits(error, 'error'), grepl('Form field needs a declared schema: username', conditionMessage(error), fixed = TRUE),
      !file.exists(file.path(directory, 'unexpected-http')))
  }
  jsonlite::write_json(list(issue = 'https://github.com/seanthimons/specmill/issues/178', operations = 3L,
    localhost_only = TRUE, http_requests = 0L, canonical_allows_additional_properties = TRUE,
    generated_validation_rejects_username = TRUE), 'dev/chet-admin-auth/held-form-proof.json', auto_unbox = TRUE, pretty = TRUE)
}, finally = {
  server$kill()
  unlink(directory, recursive = TRUE)
})
