# Exercise actual JSON encoding and HTTP status handling against localhost.
suppressMessages(devtools::load_all('.', quiet = TRUE))
directory <- tempfile('amos-http-')
dir.create(directory)
status_file <- file.path(directory, 'status')
writeLines('200', status_file)
server <- callr::r_bg(function(directory, status_file) {
  count <- 0L
  port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1', port, list(call = function(req) {
    count <<- count + 1L
    saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO,
      media = req$CONTENT_TYPE, body = req$rook.input$read()),
      file.path(directory, sprintf('request-%04d.rds', count)))
    list(status = as.integer(readLines(status_file)),
      headers = list('Content-Type' = 'application/json'),
      body = '{"substances":[{"dtxsid":"one","missing":null}]}')
  }))
  saveRDS(port, file.path(directory, 'port.rds'))
  repeat httpuv::service(50)
}, args = list(directory, status_file))
local({
  on.exit({server$kill(); unlink(directory, recursive = TRUE)})
  for (i in seq_len(500L)) {
    if (file.exists(file.path(directory, 'port.rds'))) break
    if (!server$is_alive()) stop('Local HTTP server failed')
    Sys.sleep(0.02)
  }
  stopifnot(file.exists(file.path(directory, 'port.rds')))
  withr::local_options(list(ComptoxR.chemi_burl = paste0('http://127.0.0.1:',
    readRDS(file.path(directory, 'port.rds')), '/api')))
  testthat::local_mocked_bindings(req_retry = function(req, ...) req, .package = 'httr2')
  captures <- function() lapply(sort(list.files(directory,
    pattern = '^request-', full.names = TRUE)), readRDS)
  a <- chemi_amos_dtxsids(c('one', 'café', 'one', '', NA_character_))
  first <- tail(captures(), 1L)[[1L]]
  b <- chemi_amos_dtxsids(dtxsids = c('one', 'café', 'one', '', NA_character_))
  stopifnot(identical(a, b), identical(first, tail(captures(), 1L)[[1L]]),
    first$method == 'POST', first$path == '/api/amos/dtxsids/',
    first$media == 'application/json',
    identical(jsonlite::fromJSON(rawToChar(first$body))$dtxsids, c('one', 'café')))
  chemi_amos_dtxsids('one')
  stopifnot(identical(tail(captures(), 1L)[[1L]]$body,
    charToRaw('{"dtxsids":["one"]}')))
  for (input in list(NULL, character(), c('', NA_character_))) {
    before <- length(captures())
    result <- tryCatch(chemi_amos_dtxsids(input), error = identity)
    stopifnot(inherits(result, 'error'), length(captures()) == before)
  }
  for (name in c('chemi_amos_record_counts', 'chemi_amos_mass_spectra_for_substances',
    'chemi_amos_count_substances_in_ids')) {
    fn <- get(name, asNamespace('ComptoxR'))
    field <- names(formals(fn))[[1L]]
    fn('one')
    request <- tail(captures(), 1L)[[1L]]
    expected <- paste0('{"', field, '":["one"]}')
    stopifnot(identical(request$body, charToRaw(expected)), request$method == 'POST')
  }
  for (status in c(404L, 500L, 401L)) {
    writeLines(as.character(status), status_file)
    result <- tryCatch(chemi_amos_dtxsids('one'), error = identity)
    stopifnot(inherits(result, 'error'))
    if (status == 401L) stopifnot(inherits(result, 'specmill_call_error'))
  }
})
cat('PASS actual AMOS DTXSID JSON bytes, normalization, preflight and HTTP failures.\n')
