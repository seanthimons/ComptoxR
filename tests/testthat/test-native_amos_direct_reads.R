amos_direct_cases <- function() jsonlite::read_json(test_path('fixtures/native-amos-direct-reads.json'))

amos_direct_names <- c('chemi_amos_additional_sources_for_substance', 'chemi_amos_get_pdf_metadata',
  'chemi_amos_get_substance_file_for_record')

test_that('AMOS direct-read fixtures cover the registered public bindings', {
  expect_setequal(names(amos_direct_cases()), amos_direct_names)
  expect_true(all(amos_direct_names %in% getNamespaceExports('ComptoxR')))
})

test_that('new AMOS reads send exact schema requests and decode real localhost responses', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  directory <- tempfile('amos-direct-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  response_file <- file.path(directory, 'response.rds')
  saveRDS(list(status = 200L, media = 'application/json', body = '{"nested":{"ids":[1,2]},"nullable":null}'), response_file)
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      saveRDS(list(method = request$REQUEST_METHOD, uri = request$PATH_INFO,
        query = request$QUERY_STRING, body = rawToChar(request$rook.input$read()),
        content_type = request$CONTENT_TYPE, accept = request$HTTP_ACCEPT,
        api_key = request$HTTP_X_API_KEY, authorization = request$HTTP_AUTHORIZATION), file.path(directory, 'request.rds'))
      response <- readRDS(file.path(directory, 'response.rds'))
      list(status = response$status, headers = list(`Content-Type` = response$media, Connection = 'close'), body = response$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(100)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(400L)) {
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
    list(status = 200L, media = 'application/vnd.ms-excel', body = readRDS(test_path('fixtures/native-amos-direct-workbook.rds')), result = readRDS(test_path('fixtures/native-amos-direct-workbook.rds'))),
    list(status = 200L, media = 'application/octet-stream', body = as.raw(c(0, 1, 255, 10)), result = as.raw(c(0, 1, 255, 10))),
    list(status = 200L, media = 'text/csv', body = 'name,id\n"A,B",1\n', result = 'name,id\n"A,B",1\n'),
    list(status = 204L, media = 'application/json', body = '', result = NULL))
  for (name in names(amos_direct_cases())) {
    case <- amos_direct_cases()[[name]]
    fn <- getExportedValue('ComptoxR', name)
    if (file.exists(test_path('..', '..', 'specmill.yml'))) {
      expect_true(file.exists(test_path('..', '..', 'man', paste0(name, '.Rd'))))
    }
    for (response in responses) {
      saveRDS(response, response_file)
      expect_identical(do.call(fn, case$args), response$result, info = name)
      sent <- readRDS(file.path(directory, 'request.rds'))
      expect_identical(sent$method, 'GET', info = name)
      expected_path <- case$path
      for (field in names(case$args)) expected_path <- sub(paste0('{', field, '}'), case$args[[field]], expected_path, fixed = TRUE)
      expect_identical(utils::URLdecode(sent$uri), expected_path, info = name)
      expect_identical(sent$query, '', info = name)
      expect_identical(sent$body, '', info = name)
      expect_identical(sent$accept, '*/*', info = name)
      expect_null(sent$api_key)
      expect_null(sent$authorization)
    }
    saveRDS(responses[[1L]], response_file)
    encoded_args <- lapply(case$args, function(x) 'a / + café')
    expect_identical(do.call(fn, encoded_args), responses[[1L]]$result)
    sent <- readRDS(file.path(directory, 'request.rds'))
    expect_identical(sent$uri, gsub('\\{[^}]+\\}', 'a%20%2F%20%2B%20caf%C3%A9', case$path))
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

test_that('new AMOS reads preserve transport condition identity', {
  original <- structure(list(message = 'transport sentinel', call = NULL),
    class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition'))
  local_mocked_bindings(req_perform = function(...) stop(original), .package = 'httr2')
  for (name in names(amos_direct_cases())) {
    expect_identical(tryCatch(do.call(getExportedValue('ComptoxR', name), amos_direct_cases()[[name]]$args), error = identity), original)
  }
})


test_that('AMOS direct reads encode each identifier as one segment and reject invalid inputs', {
  requests <- list()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L, headers = list(`Content-Type`='application/json'), body=charToRaw('{}'))
  }, .package='httr2')
  for(name in names(amos_direct_cases())) {
    fn <- getExportedValue('ComptoxR',name)
    args <- amos_direct_cases()[[name]]$args
    expect_identical(names(formals(fn)),names(args))
    for(field in names(args)) {
      changed <- args; changed[[field]] <- 'a / + café'
      do.call(fn,changed)
      expect_match(tail(requests,1L)[[1L]]$url,'a%20%2F%20%2B%20caf%C3%A9',fixed=TRUE)
      for(value in list(NULL,NA_character_,character(),c('a','b'),1,list('a'))) {
        invalid <- args; invalid[field] <- list(value)
        before <- length(requests)
        expect_error(do.call(fn,invalid))
        expect_length(requests,before)
      }
    }
    expect_error(fn())
  }
})


test_that('captured production AMOS download is an actual populated workbook', {
  bytes <- readRDS(test_path('fixtures/native-amos-direct-workbook.rds'))
  path <- tempfile(fileext='.xlsx'); on.exit(unlink(path),add=TRUE); writeBin(bytes,path)
  members <- utils::unzip(path,list=TRUE)$Name
  expect_true(all(c('xl/workbook.xml','xl/worksheets/sheet1.xml') %in% members))
  contents <- paste(readLines(unz(path,'xl/worksheets/sheet1.xml'),warn=FALSE),collapse='')
  expect_match(contents,'DTXSID',fixed=TRUE)
})
