# Executes the isolated official output only. No package or deployed calls.
testthat::test_that('reviewed standardizer preflight preserves multipart bytes and native failures', {
  work <- path.expand('~/.cache/comptoxr-specmill-finish/canonical-holds-candidate')
  env <- new.env(parent = globalenv())
  for (file in c('api_validation.R', 'z_specmill_request.R', 'service_endpoints.R',
    'chemi_stdizer_groups_preflight_post.R')) sys.source(file.path(work, 'R', file), env)
  fn <- env$chemi_stdizer_groups_preflight_post
  testthat::expect_identical(names(formals(fn)), 'body')
  testthat::expect_identical(env$.endpoint_default('chemi_burl'), 'https://hcd.rtpnc.epa.gov/api')
  directory <- tempfile('preflight-wire-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  response <- list(status = 200L, media = 'application/json', body = charToRaw('[{"name":"localhost group"}]'))
  saveRDS(response, file.path(directory, 'response.rds'))
  server <- callr::r_bg(function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      count <<- count + 1L
      saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, query = req$QUERY_STRING,
        content_type = req$CONTENT_TYPE, body = req$rook.input$read()),
        file.path(directory, paste0(count, '.rds')))
      r <- readRDS(file.path(directory, 'response.rds'))
      list(status = r$status, headers = list(`Content-Type` = r$media, Connection = 'close'), body = r$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(50)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  stopifnot(file.exists(file.path(directory, 'ready.rds')))
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')), '/api'),
    comptoxr_native.request = list(timeout = 5, max_retries = 0L)))
  count <- 0L
  wires <- list()
  invoke <- function(body) {
    count <<- count + 1L
    value <- tryCatch(fn(body), error = identity)
    wires[[count]] <<- readRDS(file.path(directory, paste0(count, '.rds')))
    value
  }
  files <- list(as.raw(c(65, 0, 255, 10)), as.raw(c(66, 0, 128, 34)))
  body <- setNames(list(files), 'files[]')
  parts <- function(wire) {
    testthat::expect_identical(wire$method, 'POST')
    testthat::expect_identical(wire$path, '/api/stdizer/groups/preflight')
    testthat::expect_true(is.null(wire$query) || wire$query %in% c('', '?'))
    testthat::expect_match(wire$content_type, '^multipart/form-data; boundary=')
    marker <- charToRaw(paste0('--', sub('.*boundary=', '', wire$content_type)))
    starts <- grepRaw(marker, wire$body, fixed = TRUE, all = TRUE)
    testthat::expect_length(starts, 3L)
    lapply(seq_len(length(starts) - 1L), function(i) {
      bytes <- wire$body[seq.int(starts[[i]] + length(marker) + 2L, starts[[i + 1L]] - 3L)]
      split <- grepRaw(charToRaw('\r\n\r\n'), bytes, fixed = TRUE)[[1L]]
      header <- rawToChar(bytes[seq_len(split - 1L)])
      testthat::expect_match(header, 'name="files\\[\\]"')
      testthat::expect_match(header, 'Content-Type: application/octet-stream', ignore.case = TRUE)
      bytes[seq.int(split + 4L, length(bytes))]
    })
  }
  testthat::expect_identical(invoke(body), list(list(name = 'localhost group')))
  testthat::expect_identical(parts(wires[[count]]), files)
  file_body <- body
  for (i in seq_along(files)) {
    path <- file.path(directory, paste0('file', i, '.json'))
    writeBin(files[[i]], path)
    file_body[['files[]']][[i]] <- curl::form_file(path)
  }
  testthat::expect_identical(invoke(file_body), list(list(name = 'localhost group')))
  testthat::expect_identical(parts(wires[[count]]), files)
  testthat::expect_error(fn(), 'Required body')
  for (invalid in list(NULL, 'wrong', list(), list('files[]' = 'wrong'))) {
    testthat::expect_error(fn(invalid))
    testthat::expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
  }
  for (status in c(400L, 401L, 404L, 500L)) {
    response$status <- status
    response$body <- charToRaw('{"error":"localhost"}')
    saveRDS(response, file.path(directory, 'response.rds'))
    error <- invoke(body)
    testthat::expect_s3_class(error, if (status == 401L) 'specmill_call_error' else paste0('httr2_http_', status))
    if (status != 401L) testthat::expect_identical(httr2::resp_body_json(error$resp), list(error = 'localhost'))
  }
  response$status <- 200L
  for (sample in list(
    list(media = 'text/plain', body = charToRaw('headers'), value = 'headers'),
    list(media = 'application/octet-stream', body = as.raw(c(0, 255)), value = as.raw(c(0, 255))),
    list(media = 'application/json', body = charToRaw('{bad'), value = NULL))) {
    response$media <- sample$media
    response$body <- sample$body
    saveRDS(response, file.path(directory, 'response.rds'))
    value <- invoke(body)
    if (is.null(sample$value)) testthat::expect_s3_class(value, 'error') else
      testthat::expect_identical(value, sample$value)
  }
  response$status <- 204L
  response$body <- raw()
  saveRDS(response, file.path(directory, 'response.rds'))
  testthat::expect_null(invoke(body))
  server$kill()
  error <- tryCatch(fn(body), error = identity)
  testthat::expect_s3_class(error, 'httr2_failure')
  saveRDS(wires, 'localhost-wire.rds', version = 2)
})
