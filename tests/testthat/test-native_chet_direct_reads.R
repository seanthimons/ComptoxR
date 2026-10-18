chet_direct_cases <- function() jsonlite::read_json(test_path('fixtures/native-chet-direct-reads.json'))

chet_direct_names <- c('chemi_chet_metadata', 'chemi_chet_version',
  'chemi_chet_curators_me', 'chemi_chet_chemicals_chemtemp')

test_that('CheT direct-read fixtures cover the registered public bindings', {
  expect_setequal(names(chet_direct_cases()), chet_direct_names)
  expect_true(all(chet_direct_names %in% getNamespaceExports('ComptoxR')))
})

test_that('new CheT reads send exact schema requests and decode real localhost responses', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  directory <- tempfile('chet-direct-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  response_file <- file.path(directory, 'response.rds')
  saveRDS(list(status = 200L, media = 'application/json', body = '{"nested":{"ids":[1,2]},"nullable":null}'), response_file)
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      saveRDS(list(method = request$REQUEST_METHOD, uri = request$PATH_INFO,
        query = request$QUERY_STRING, body = rawToChar(request$rook.input$read()),
        content_type = request$CONTENT_TYPE), file.path(directory, 'request.rds'))
      response <- readRDS(file.path(directory, 'response.rds'))
      list(status = response$status, headers = list(`Content-Type` = response$media, Connection = 'close'), body = response$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(100)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(100L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 15)))
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  responses <- list(
    list(status = 200L, media = 'application/json; charset=utf-8', body = '{"nested":{"ids":[1,2]},"nullable":null}',
      result = list(nested = list(ids = list(1L, 2L)), nullable = NULL)),
    list(status = 200L, media = 'application/octet-stream', body = as.raw(c(0, 1, 255, 10)), result = as.raw(c(0, 1, 255, 10))),
    list(status = 200L, media = 'text/csv', body = 'name,id\n"A,B",1\n', result = 'name,id\n"A,B",1\n'),
    list(status = 204L, media = 'application/json', body = '', result = NULL))
  for (name in names(chet_direct_cases())) {
    case <- chet_direct_cases()[[name]]
    fn <- getExportedValue('ComptoxR', name)
    expect_true(file.exists(test_path('..', '..', 'man', paste0(name, '.Rd'))))
    for (response in responses) {
      saveRDS(response, response_file)
      expect_identical(do.call(fn, case$args), response$result, info = name)
      sent <- readRDS(file.path(directory, 'request.rds'))
      expect_identical(sent$method, 'GET', info = name)
      expect_identical(sent$uri, case$path, info = name)
      expect_identical(sent$query, '', info = name)
      expect_identical(sent$body, '', info = name)
    }
    for (status in c(400L, 404L, 500L, 401L)) {
      saveRDS(list(status = status, media = 'application/problem+json', body = '{"detail":"wire sentinel"}'), response_file)
      condition <- tryCatch(do.call(fn, case$args), error = identity)
      if (inherits(condition, 'httr2_failure')) stop(condition)
      if (status == 401L) expect_s3_class(condition, 'specmill_call_error')
      else {
        expect_s3_class(condition, paste0('httr2_http_', status))
        expect_identical(httr2::resp_status(condition$resp), status)
        expect_identical(httr2::resp_body_string(condition$resp), '{"detail":"wire sentinel"}')
      }
    }
    saveRDS(list(status = 200L, media = 'application/json', body = '{'), response_file)
    expect_error(do.call(fn, case$args), 'Cannot decode')
  }
})

test_that('new CheT input contracts reject invalid values before transport', {
  requests <- 0L
  local_mocked_bindings(req_perform = function(...) { requests <<- requests + 1L; stop('transport reached') }, .package = 'httr2')
  expect_error(chemi_chet_chemicals_chemtemp())
  expect_error(chemi_chet_chemicals_chemtemp('type'))
  for (value in list(NULL, NA_character_, character(), c('a', 'b'), 1, list('a'))) {
    expect_error(chemi_chet_chemicals_chemtemp(value, 'value'))
    expect_error(chemi_chet_chemicals_chemtemp('type', value))
  }
  expect_identical(requests, 0L)
})

test_that('new CheT reads preserve transport condition identity', {
  original <- structure(list(message = 'transport sentinel', call = NULL),
    class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition'))
  local_mocked_bindings(req_perform = function(...) stop(original), .package = 'httr2')
  for (name in names(chet_direct_cases())) {
    expect_identical(tryCatch(do.call(getExportedValue('ComptoxR', name), chet_direct_cases()[[name]]$args), error = identity), original)
  }
})
