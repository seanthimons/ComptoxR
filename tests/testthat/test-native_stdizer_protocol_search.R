testthat::test_that('protocol search sends reviewed paging fields and preserves native behavior', {
  testthat::skip_if_not_installed('httpuv')
  testthat::skip_if_not_installed('callr')
  fn <- chemi_stdizer_protocols_by_id_post
  testthat::expect_identical(names(formals(fn)), c('id', 'page', 'size', 'sort', 'body'))
  directory <- tempfile('protocol-search-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  reply <- list(status = 200L, media = 'application/json',
    body = charToRaw('{"id":"protocol","filteredNumber":2,"records":[{"id":"one"},{"id":"two"}]}'))
  saveRDS(reply, file.path(directory, 'reply.rds'))
  server <- callr::r_bg(function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      count <<- count + 1L
      saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, query = req$QUERY_STRING,
        content_type = req$CONTENT_TYPE, body = req$rook.input$read()),
        file.path(directory, paste0(count, '.rds')))
      r <- readRDS(file.path(directory, 'reply.rds'))
      list(status = r$status, headers = list(`Content-Type` = r$media, Connection = 'close'), body = r$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(20)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(400L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  testthat::expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  url <- paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')))
  withr::local_options(list(ComptoxR.chemi_burl = paste0(url, '/api'),
    comptoxr_native.request = list(timeout = 3, max_retries = 0L)))
  count <- 0L
  wire <- function() {
    value <- readRDS(file.path(directory, paste0(count, '.rds')))
    if (!is.null(value$query)) value$query <- sub('^\\?', '', value$query)
    value
  }
  invoke <- function(args) {
    value <- tryCatch(do.call(fn, args), error = identity)
    count <<- count + 1L
    value
  }
  decoded <- jsonlite::fromJSON(rawToChar(reply$body), simplifyVector = FALSE)
  testthat::expect_identical(invoke(list(id = 'protocol', body = list())), decoded)
  testthat::expect_identical(wire()$method, 'POST')
  testthat::expect_identical(wire()$path, '/api/stdizer/protocols/protocol')
  testthat::expect_true(is.null(wire()$query) || wire()$query %in% c('', '?'))
  testthat::expect_identical(rawToChar(wire()$body), '{}')
  testthat::expect_match(wire()$content_type, '^application/json')
  local({
    withr::local_envvar(chemi_burl = NA)
    withr::local_options(list(ComptoxR.chemi_burl = NULL, comptoxr_native.dry_run = TRUE))
    request <- fn('protocol', body = list())
    testthat::expect_s3_class(request, 'httr2_request')
    testthat::expect_identical(request$url, 'https://hcd.rtpnc.epa.gov/api/stdizer/protocols/protocol')
  })
  args <- list(id = 'protocol', page = 0L, size = 1L,
    sort = c('type,asc', 'id,desc'), body = list(hidden = FALSE, query = 'x & y'))
  testthat::expect_identical(invoke(args), decoded)
  testthat::expect_identical(wire()$query, 'page=0&size=1&sort=type%2Casc&sort=id%2Cdesc')
  testthat::expect_identical(jsonlite::fromJSON(rawToChar(wire()$body), simplifyVector = FALSE), args$body)
  args$sort <- character()
  testthat::expect_identical(invoke(args), decoded)
  testthat::expect_identical(wire()$query, 'page=0&size=1')
  args$sort <- 'id,desc&size=999'
  testthat::expect_identical(invoke(args), decoded)
  testthat::expect_identical(wire()$query, 'page=0&size=1&sort=id%2Cdesc%26size%3D999')
  args$sort <- ''
  testthat::expect_identical(invoke(args), decoded)
  testthat::expect_identical(wire()$query, 'page=0&size=1&sort=')
  invalid <- list(list(), list(id = 'protocol'), list(id = 'protocol', body = NULL),
    list(id = 1L, body = list()), list(id = c('one', 'two'), body = list()),
    list(id = 'protocol', page = -1L, body = list()), list(id = 'protocol', size = 0L, body = list()),
    list(id = 'protocol', page = 1.5, body = list()), list(id = 'protocol', size = c(1, 2), body = list()),
    list(id = 'protocol', sort = 1L, body = list()), list(id = 'protocol', sort = c('id', NA), body = list()),
    list(id = 'protocol', body = list(hidden = 0)), list(id = 'protocol', body = list(hidden = NULL)))
  for (args in invalid) {
    testthat::expect_error(do.call(fn, args))
    testthat::expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
  }
  for (status in c(400L, 404L, 500L, 401L)) {
    failed <- list(status = status, media = 'application/problem+json', body = charToRaw('{"error":"protocol fixture"}'))
    saveRDS(failed, file.path(directory, 'reply.rds'))
    value <- invoke(list(id = 'protocol', body = list()))
    testthat::expect_s3_class(value, if (status == 401L) 'specmill_call_error' else paste0('httr2_http_', status))
    if (status != 401L) testthat::expect_identical(httr2::resp_body_raw(value$resp), failed$body)
  }
  saveRDS(list(status = 204L, media = 'application/json', body = raw()), file.path(directory, 'reply.rds'))
  testthat::expect_null(invoke(list(id = 'protocol', body = list())))
  withr::local_options(list(comptoxr_native.request = list(timeout = 0)))
  testthat::expect_error(fn('protocol', body = list()), class = 'specmill_call_error')
  testthat::expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
  options(comptoxr_native.request = list(timeout = 1, max_retries = 0L))
  server$kill()
  testthat::expect_error(fn('protocol', body = list()), class = 'httr2_failure')
})
