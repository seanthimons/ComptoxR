test_that('CheT chemical download validates before HTTP and preserves GET JSON on the wire', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  directory <- tempfile('chet-dl-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  csv <- readChar(test_path('fixtures/chet-chemical-dl.csv'), file.info(test_path('fixtures/chet-chemical-dl.csv'))$size)
  server <- callr::r_bg(function(directory, csv) {
    requests <- list()
    port <- httpuv::randomPort()
    handle <- httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      body <- rawToChar(req$rook.input$read())
      requests[[length(requests) + 1L]] <<- list(method = req$REQUEST_METHOD,
        path = req$PATH_INFO, query = req$QUERY_STRING, type = req$CONTENT_TYPE, body = body)
      saveRDS(requests, file.path(directory, 'requests.rds'))
      value <- jsonlite::fromJSON(body, simplifyVector = FALSE)
      if (isTRUE(value$fail)) return(list(status = 400L,
        headers = list('Content-Type' = 'application/json'), body = '{"detail":"rejected"}'))
      if (isTRUE(value$binary)) return(list(status = 200L,
        headers = list('Content-Type' = 'application/octet-stream'), body = charToRaw(csv)))
      list(status = 200L, headers = list('Content-Type' = 'text/csv; charset=utf-8'), body = csv)
    }))
    on.exit(handle$stop(), add = TRUE)
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(100)
  }, list(directory, csv), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    comptoxr_native.dry_run = FALSE,
    comptoxr_native.request = list(base_url = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')), '/api/chet'), max_retries = 0)
  ))
  download <- chemi_chet_chemicals_chemical_dl
  empty <- stats::setNames(list(), character())
  expect_identical(download(empty), csv)
  calls <- function() readRDS(file.path(directory, 'requests.rds'))
  expect_identical(calls()[[1L]], list(method = 'GET', path = '/api/chet/chemicals/chemical_DL',
    query = '', type = 'application/json', body = '{}'))
  fields <- list(ids = list('one', 'two'), filter = list(active = TRUE, nested = list(count = 2L)))
  expect_identical(download(fields), csv)
  expect_identical(jsonlite::fromJSON(calls()[[2L]]$body, simplifyVector = FALSE), fields)
  for (invalid in list(NULL, 'invalid', 1L, list(1L))) expect_error(download(invalid))
  expect_error(download())
  expect_length(calls(), 2L)
  expect_identical(download(list(binary = TRUE)), charToRaw(csv))
  expect_error(download(list(fail = TRUE)), '400')
  expect_length(calls(), 4L)
  connection <- textConnection(csv)
  counts <- utils::count.fields(connection, sep = ',', quote = '"', comment.char = '')
  close(connection)
  expect_identical(counts, c(rep(6L, 3L), rep(1L, 30L)))
  records <- utils::read.csv(text = csv, check.names = FALSE, colClasses = 'character')
  expect_identical(names(records), c('Name', 'DTXSID', 'SMILES', 'InChI Key', 'CASRN', 'Representative'))
  expect_equal(nrow(records), 2L)
  expect_identical(records$DTXSID, c('DTXSID0024185', 'DTXSID1027186'))
})
