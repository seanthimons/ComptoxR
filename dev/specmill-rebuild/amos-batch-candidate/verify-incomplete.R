# Exercise generated candidate functions through the actual native transport.
out <- 'dev/specmill-rebuild/amos-batch-candidate'
work <- path.expand('~/.cache/comptoxr-specmill-finish/amos-batch-candidate')
env <- new.env(parent = globalenv())
for (file in c('R/api_validation.R', 'R/z_specmill_request.R', 'R/service_endpoints.R', 'R/api_auth.R')) {
  sys.source(file, env)
}
names <- c('chemi_amos_batch', 'chemi_amos_analytical_qc_batch')
legacy <- new.env(parent = globalenv())
for (name in names) {
  sys.source(file.path(work, 'R', paste0(name, '.R')), env)
  sys.source(file.path('R', paste0(name, '.R')), legacy)
}
checks <- 0L
assert <- function(value) {
  stopifnot(isTRUE(value))
  checks <<- checks + 1L
}
for (name in names) assert(identical(formals(env[[name]]), formals(legacy[[name]])))
directory <- tempfile('amos-batch-wire-')
dir.create(directory)
response <- list(status = 200L, media = 'application/vnd.ms-excel', body = as.raw(c(80, 75, 0, 255, 128, 10)))
saveRDS(response, file.path(directory, 'response.rds'))
server <- callr::r_bg(function(directory) {
  count <- 0L
  port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1', port, list(call = function(req) {
    count <<- count + 1L
    saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, query = req$QUERY_STRING,
      content_type = req$CONTENT_TYPE, accept = req$HTTP_ACCEPT, body = req$rook.input$read()),
      file.path(directory, paste0(count, '.rds')))
    r <- readRDS(file.path(directory, 'response.rds'))
    list(status = r$status, headers = list(`Content-Type` = r$media, Connection = 'close'), body = r$body)
  }))
  saveRDS(port, file.path(directory, 'ready.rds'))
  repeat httpuv::service(20)
}, args = list(directory), supervise = TRUE)
for (i in seq_len(400L)) {
  if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
  Sys.sleep(0.05)
}
assert(file.exists(file.path(directory, 'ready.rds')))
port <- readRDS(file.path(directory, 'ready.rds'))
options(ComptoxR.chemi_burl = paste0('http://127.0.0.1:', port),
  comptoxr_native.request = list(timeout = 3, max_retries = 0L))
source <- jsonlite::read_json('dev/specmill-rebuild/sources/amos-staging-2026-10-18.json')
paths <- c('/api/amos/batch_search', '/api/amos/analytical_qc_batch_search')
requests <- 0L
wires <- list()
calls <- list()
for (index in seq_along(names)) {
  name <- names[[index]]
  expected <- source$paths[[paths[[index]]]]$post$requestBody$content[['application/json']]$example
  args <- expected
  args$ids <- unlist(args$identifiers)
  args$identifiers <- NULL
  args$exclude_analytical_qc <- NULL
  calls[[name]] <- args
  fn <- env[[name]]
  invoke <- function(args) tryCatch(do.call(fn, args), error = identity)
  value <- invoke(args)
  assert(identical(value, response$body))
  requests <- requests + 1L
  wire <- readRDS(file.path(directory, paste0(requests, '.rds')))
  wires[[name]] <- wire
  assert(identical(wire$method, 'POST'))
  assert(identical(wire$path, paths[[index]]))
  assert(is.null(wire$query) || wire$query %in% c('', '?'))
  assert(grepl('^application/json', wire$content_type))
  assert(identical(wire$accept, 'application/vnd.ms-excel'))
  body <- jsonlite::fromJSON(rawToChar(wire$body), simplifyVector = FALSE)
  assert(setequal(names(body), names(expected)))
  assert(identical(body[names(expected)], expected))
  many <- args
  many$ids <- c(args$ids, args$ids)
  assert(identical(invoke(many), response$body))
  requests <- requests + 1L
  sent <- readRDS(file.path(directory, paste0(requests, '.rds')))
  assert(identical(jsonlite::fromJSON(rawToChar(sent$body))$identifiers, many$ids))
  assert(!file.exists(file.path(directory, paste0(requests + 1L, '.rds'))))
  invalid <- list(list(), modifyList(args, list(ids = 1L)), modifyList(args, list(ids = character())),
    modifyList(args, list(ids = list(1L))), modifyList(args, list(ids = NA_character_)),
    modifyList(args, list(include_classyfire = 0)), modifyList(args, list(methodologies = list(all = 0))))
  null_ids <- args
  null_ids['ids'] <- list(NULL)
  invalid <- c(invalid, list(null_ids))
  for (bad in invalid) {
    assert(inherits(invoke(bad), 'error'))
    assert(!file.exists(file.path(directory, paste0(requests + 1L, '.rds'))))
  }
  for (status in c(400L, 500L, 401L)) {
    failed <- list(status = status, media = 'application/problem+json', body = charToRaw('{"error":"candidate"}'))
    saveRDS(failed, file.path(directory, 'response.rds'))
    error <- invoke(args)
    requests <- requests + 1L
    assert(inherits(error, if (status == 401L) 'specmill_call_error' else paste0('httr2_http_', status)))
    if (status != 401L) assert(identical(httr2::resp_body_raw(error$resp), failed$body))
  }
  saveRDS(response, file.path(directory, 'response.rds'))
  workbook <- readBin(file.path('dev/specmill-rebuild/canonical-holds-audit/amos-batch-recheck',
    if (index == 1L) 'staging-general-response.bin' else 'production-analytical-response.bin'), 'raw', n = 1e7)
  saveRDS(list(status = 200L, media = 'application/vnd.ms-excel', body = workbook), file.path(directory, 'response.rds'))
  assert(identical(invoke(args), workbook))
  requests <- requests + 1L
  saveRDS(response, file.path(directory, 'response.rds'))
}
server$kill()
for (name in names) {
  error <- tryCatch(do.call(env[[name]], calls[[name]]), error = identity)
  assert(inherits(error, 'httr2_failure'))
}
options(ComptoxR.chemi_burl = '')
for (name in names) {
  error <- tryCatch(do.call(env[[name]], calls[[name]]), error = identity)
  assert(inherits(error, 'cli_error'))
  assert(grepl('Configure', conditionMessage(error), fixed = TRUE))
}
options(ComptoxR.chemi_burl = paste0('http://127.0.0.1:', port),
  comptoxr_native.request = list(timeout = 0))
for (name in names) {
  error <- tryCatch(do.call(env[[name]], calls[[name]]), error = identity)
  assert(inherits(error, 'specmill_call_error'))
}
saveRDS(list(assertions = checks, requests = requests, wires = wires, calls = calls), file.path(out, 'localhost.rds'))
jsonlite::write_json(list(assertions = checks, requests = requests, failures = 0L,
  root_adoption = FALSE, public_formals_unchanged = TRUE, native_helper_unchanged = TRUE),
  file.path(out, 'localhost.json'), pretty = TRUE, auto_unbox = TRUE)
unlink(directory, recursive = TRUE)
cat('PASS:', checks, 'assertions,', requests, 'actual localhost requests.\n')
