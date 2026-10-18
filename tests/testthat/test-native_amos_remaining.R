amos_remaining_cases <- list(
  chemi_amos_substances_for_ids = list(internal_id_list = c('FS-26369', 'GJ-004')),
  chemi_amos_retrieve_fact_sheets = list(internal_ids = 'FS-26369'),
  chemi_amos_retrieve_product_declarations = list(internal_ids = 'PD-1'),
  chemi_amos_retrieve_safety_data_sheets = list(internal_ids = 'SDS-1'),
  chemi_amos_for_document_ids = list(record_type = 'Fact Sheet', search_info = list(internal_id = list(value = 'FS-10313', exact = TRUE)), record_info_fields = 'internal_id')
)

test_that('AMOS reads send flat declared fields and preserve original public signatures', {
  fixture <- readRDS(test_path('fixtures/native-amos-remaining.rds'))
  sent <- NULL; observed <- 0L
  local_mocked_bindings(observe_api_responses = function(...) observed <<- observed + 1L)
  local_mocked_bindings(req_perform = function(req, ...) {
    sent <<- req
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'), body = charToRaw('{"results":[]}'))
  }, .package = 'httr2')
  for (name in names(amos_remaining_cases)) {
    args <- amos_remaining_cases[[name]]
    fn <- get(name, asNamespace('ComptoxR')); old <- eval(fixture$legacy[[name]][[3L]], asNamespace('ComptoxR'))
    expect_identical(formals(fn), formals(old), info = name)
    observed <- 0L
    expect_identical(do.call(fn, args), list(results = list()), info = name)
    expect_identical(observed, 1L)
    expect_identical(sent$method, 'POST')
    expect_setequal(names(sent$body$data), setdiff(names(args), 'record_type'))
    expect_length(httr2::url_parse(sent$url)$query, 0L)
    for (field in setdiff(names(args), 'record_type')) {
      if (field %in% c('ids', 'internal_ids', 'internal_id_list', 'record_info_fields', 'table_fields')) {
        expect_identical(unname(as.list(unclass(sent$body$data[[field]]))), unname(as.list(args[[field]])), info = paste(name, field))
      } else expect_identical(sent$body$data[[field]], args[[field]], info = paste(name, field))
    }
    if ('record_type' %in% names(args)) expect_match(sent$url, '/Fact%20Sheet', fixed = TRUE)
  }
})

test_that('AMOS exports preserve actual Excel bytes and reject missing identifiers before HTTP', {
  fixture <- readRDS(test_path('fixtures/native-amos-remaining.rds'))
  workbook <- fixture$live$substances_for_ids$body
  path <- tempfile(fileext = '.xlsx'); on.exit(unlink(path), add = TRUE); writeBin(workbook, path)
  expect_true(all(c('xl/workbook.xml', 'xl/worksheets/sheet1.xml') %in% utils::unzip(path, list = TRUE)$Name))
  requests <- 0L
  local_mocked_bindings(req_perform = function(req, ...) {
    requests <<- requests + 1L
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/vnd.ms-excel'), body = workbook)
  }, .package = 'httr2')
  for (name in 'chemi_amos_substances_for_ids') {
    fn <- get(name, asNamespace('ComptoxR'))
    expect_identical(do.call(fn, amos_remaining_cases[[name]]), workbook, info = name)
  }
  for (name in setdiff(names(amos_remaining_cases), 'chemi_amos_for_document_ids')) {
    requests <- 0L
    expect_error(get(name, asNamespace('ComptoxR'))(), 'Supply at least one identifier')
    expect_identical(requests, 0L)
  }
  requests <- 0L
  expect_error(chemi_amos_substances_for_ids(internal_id_list = list(list(bad = 'invalid'))))
  expect_identical(requests, 0L)
})

test_that('AMOS transport, received HTTP, malformed JSON and hard call failures remain distinct', {
  response <- NULL
  original <- structure(list(message = 'transport sentinel', call = NULL, resp = NULL),
    class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition'))
  local_mocked_bindings(req_perform = function(req, ...) {
    if (is.null(response)) stop(original)
    policy <- req$policies$error_is_error
    if (httr2::resp_status(response) >= 400L && (is.null(policy) || isTRUE(policy(response)))) httr2::resp_check_status(response)
    response
  }, .package = 'httr2')
  for (name in names(amos_remaining_cases)) {
    fn <- get(name, asNamespace('ComptoxR')); args <- amos_remaining_cases[[name]]
    response <- NULL
    expect_identical(tryCatch(do.call(fn, args), error = identity), original)
    for (status in c(404L, 500L, 401L)) {
      response <- httr2::response(status_code = status, headers = list(`Content-Type` = 'text/html'), body = charToRaw('failure'))
      if (status == 401L) expect_error(do.call(fn, args), class = 'specmill_call_error')
      else expect_error(do.call(fn, args), class = paste0('httr2_http_', status))
    }
    response <- httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'), body = charToRaw('{'))
    expect_error(do.call(fn, args), class = 'simpleError')
  }
})

test_that('reviewed AMOS reads send exact JSON requests to the selected production-style server', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  fixture <- readRDS(test_path('fixtures/native-amos-remaining.rds'))
  directory <- tempfile('amos-wire-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  server <- callr::r_bg(function(directory, workbook) {
    port <- httpuv::randomPort(); requests <- list()
    app <- list(call = function(request) {
      body <- request$rook.input$read()
      requests[[length(requests) + 1L]] <<- list(method = request$REQUEST_METHOD,
        path = request$PATH_INFO, query = request$QUERY_STRING,
        content_type = request$CONTENT_TYPE, accept = request$HTTP_ACCEPT, body = rawToChar(body))
      saveRDS(requests, file.path(directory, 'requests.rds'))
      if (grepl('/substances_for_ids/', request$PATH_INFO, fixed = TRUE)) {
        return(list(status = 200L, headers = list(`Content-Type` = 'application/vnd.ms-excel'), body = workbook))
      }
      value <- if (grepl('/search_for_document_ids/', request$PATH_INFO, fixed = TRUE))
        '["FS-10313"]' else '{"results":[{"internal_id":"FS-10313"}]}'
      list(status = 200L, headers = list(`Content-Type` = 'application/json'), body = value)
    })
    httpuv::startServer('127.0.0.1', port, app)
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(100)
  }, args = list(directory, fixture$live$substances_for_ids$body), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(100L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))))
  for (name in names(amos_remaining_cases)) {
    args <- amos_remaining_cases[[name]]
    value <- do.call(get(name, asNamespace('ComptoxR')), args)
    if (name == 'chemi_amos_substances_for_ids') expect_identical(value, fixture$live$substances_for_ids$body)
    else if (name == 'chemi_amos_for_document_ids') expect_identical(value, list('FS-10313'))
    else expect_identical(value, list(results = list(list(internal_id = 'FS-10313'))))
    request <- tail(readRDS(file.path(directory, 'requests.rds')), 1L)[[1L]]
    expect_identical(request$method, 'POST')
    expect_identical(request$query, '')
    expect_identical(request$content_type, 'application/json')
    expected_path <- fixture$operations[[name]]
    expected_path <- sub('{record_type}', 'Fact Sheet', expected_path, fixed = TRUE)
    expect_identical(utils::URLdecode(request$path), expected_path)
    expected <- args[setdiff(names(args), 'record_type')]
    for (field in intersect(names(expected), c('internal_ids', 'internal_id_list', 'record_info_fields', 'table_fields')))
      expected[[field]] <- as.list(expected[[field]])
    expect_identical(jsonlite::fromJSON(request$body, simplifyVector = FALSE), expected)
    expect_match(request$accept, 'application/vnd.ms-excel', fixed = TRUE)
  }
})
