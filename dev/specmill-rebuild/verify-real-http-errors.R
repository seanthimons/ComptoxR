# A real HTTP response is necessary here: returning a response from a mocked
# req_perform bypasses httr2's automatic HTTP-error handling in the old client.
suppressMessages(devtools::load_all('.', quiet = TRUE))
port_file <- tempfile()
status_file <- tempfile()
writeLines('500', status_file)
server <- callr::r_bg(function(port_file, status_file) {
  port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1', port, list(call = function(req) {
    list(status = as.integer(readLines(status_file)),
      headers = list('Content-Type' = 'application/json'), body = '{"error":"local failure"}')
  }))
  writeLines(as.character(port), port_file)
  repeat httpuv::service(50)
}, args = list(port_file, status_file))
local({
  on.exit({server$kill(); unlink(c(port_file, status_file))})
  for (i in seq_len(500L)) {
    if (file.exists(port_file)) break
    if (!server$is_alive()) stop('Local HTTP server failed')
    Sys.sleep(0.02)
  }
  stopifnot(file.exists(port_file))
  url <- paste0('http://127.0.0.1:', readLines(port_file))
  withr::local_envvar(ctx_api_key = 'local-http-policy-key')
  withr::local_options(list(ComptoxR.chemi_burl = paste0(url, '/api'), ComptoxR.ctx_burl = url))
  # Remove retry delays only; actual requests and HTTP error handling stay active.
  testthat::local_mocked_bindings(req_retry = function(req, ...) req, .package = 'httr2')
  ns <- asNamespace('ComptoxR')
  for (record in readRDS('dev/specmill-rebuild/unbatched-http-legacy.rds')) {
    old <- eval(record$expr[[3L]], ns)
    native <- get(record$name, ns)
    for (status in c(404L, 500L)) {
      writeLines(as.character(status), status_file)
      invoke <- function(fn) tryCatch(suppressMessages(fn()), error = identity)
      original <- invoke(old)
      current <- invoke(native)
      stopifnot(inherits(original, 'error'), inherits(current, 'error'),
        grepl(as.character(status), conditionMessage(original)),
        grepl(as.character(status), conditionMessage(current)))
    }
  }
})
cat('PASS original/native hard errors for real localhost HTTP404/500.\n')
