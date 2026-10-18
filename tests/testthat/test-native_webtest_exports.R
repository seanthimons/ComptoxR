webtest_export_cases <- function() {
  source <- 'schema/chemi-webtest-prod.json'
  hash <- 'cf70437924a4074476c8802f78e6442ddc1b9d4be7311ccd442b6f4c294eca26'
  list(
    chemi_webtest_predict_export = list(
      args = list(body = list(format = 'PDF', predictionResult = list(id = 'local/id +'))),
      method = 'POST', path = '/api/webtest/predict/export', query = list(),
      body_media = 'application/json', source = source, source_sha256 = hash),
    chemi_webtest_export_append = list(
      args = list(body = list(predictionRequest = list(structures = list('CCO'),
        endpoints = list('LC50'), methods = list('consensus'), format = 'PDF'),
        file = as.raw(c(0, 1, 255, 10)))),
      method = 'POST', path = '/api/webtest/export-append', query = list(),
      body_media = 'multipart/form-data', source = source, source_sha256 = hash)
  )
}

test_that('WebTEST exports have generated public signatures', {
  expect_identical(names(formals(chemi_webtest_predict_export)), 'body')
  expect_identical(names(formals(chemi_webtest_export_append)), 'body')
  expect_null(formals(chemi_webtest_export_append)$body)
  expect_error(chemi_webtest_predict_export(), 'Required body')
})

test_that('WebTEST exports validate inputs and preserve actual localhost wire contracts', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  cases <- webtest_export_cases()
  expect_setequal(names(cases), names(webtest_export_cases()))
  directory <- tempfile('management-http-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  response <- list(status = 200L, media = 'application/json', body = charToRaw('{"ok":true,"items":[1,2]}'))
  saveRDS(response, file.path(directory, 'response.rds'))
  server <- callr::r_bg(function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      count <<- count + 1L
      body <- req$rook.input$read()
      saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO,
        query = req$QUERY_STRING, content_type = req$CONTENT_TYPE,
        accept = req$HTTP_ACCEPT, body = body), file.path(directory, paste0(count, '.rds')))
      result <- readRDS(file.path(directory, 'response.rds'))
      list(status = result$status, headers = list(`Content-Type` = result$media), body = result$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(50)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  count <- 0L
  invoke <- function(fn, args) {
    count <<- count + 1L
    value <- do.call(fn, args)
    list(value = value, wire = readRDS(file.path(directory, paste0(count, '.rds'))))
  }
  # Split bytes rather than text, since uploaded files can contain NULs.
  multipart <- function(wire) {
    boundary <- sub('.*boundary=', '', wire$content_type)
    marker <- charToRaw(paste0('--', boundary))
    starts <- grepRaw(marker, wire$body, fixed = TRUE, all = TRUE)
    parts <- list()
    for (i in seq_len(length(starts) - 1L)) {
      bytes <- wire$body[seq.int(starts[[i]] + length(marker) + 2L, starts[[i + 1L]] - 3L)]
      split <- grepRaw(charToRaw('\r\n\r\n'), bytes, fixed = TRUE)[[1L]]
      header <- rawToChar(bytes[seq_len(split - 1L)])
      name <- regmatches(header, regexec('; name="([^"]+)"', header))[[1L]][[2L]]
      parts[[name]] <- list(header = header, body = bytes[seq.int(split + 4L, length(bytes))])
    }
    parts
  }
  evidence <- list()
  for (name in names(cases)) {
    case <- cases[[name]]
    fn <- get(name, asNamespace('ComptoxR'))
    if (file.exists(test_path('..', '..', 'specmill.yml'))) {
      expect_identical(digest::digest(file = test_path('../..', case$source), algo = 'sha256'), case$source_sha256)
    }
    result <- invoke(fn, case$args)
    evidence[[name]] <- result$wire
    expect_identical(result$value, list(ok = TRUE, items = list(1L, 2L)), info = name)
    expect_identical(result$wire$method, case$method, info = name)
    expect_identical(result$wire$path, case$path, info = name)
    expect_identical(result$wire$accept, '*/*', info = name)
    expect_identical(sub('^\\?', '', result$wire$query), '')
    query <- httr2::url_parse(paste0('http://localhost/?', sub('^\\?', '', result$wire$query)))$query
    expected <- lapply(case$query, function(x) if (is.logical(x)) tolower(as.character(x)) else as.character(x))
    expect_equal(query, if (length(expected)) expected else NULL, info = name)
    if (is.null(case$body_media)) {
      expect_length(result$wire$body, 0L)
    } else if (case$body_media == 'application/json') {
      expect_match(result$wire$content_type, '^application/json', info = name)
      expect_identical(rawToChar(result$wire$body), '{"format":"PDF","predictionResult":{"id":"local/id +"}}')
      expect_identical(jsonlite::fromJSON(rawToChar(result$wire$body), simplifyVector = FALSE), case$args$body, info = name)
    } else {
      expect_match(result$wire$content_type, '^multipart/form-data; boundary=', info = name)
      parts <- multipart(result$wire)
      field <- setdiff(names(case$args$body), 'file')
      expect_setequal(names(parts), c(field, 'file'))
      expect_match(parts[[field]]$header, 'Content-Type: application/json', ignore.case = TRUE)
      expect_identical(rawToChar(parts[[field]]$body), '{"structures":["CCO"],"endpoints":["LC50"],"methods":["consensus"],"format":"PDF"}')
      expect_identical(jsonlite::fromJSON(rawToChar(parts[[field]]$body), simplifyVector = FALSE), case$args$body[[field]])
      expect_match(parts$file$header, 'Content-Type: application/octet-stream', ignore.case = TRUE)
      expect_identical(parts$file$body, case$args$body$file)
      file <- file.path(directory, 'upload.bin')
      writeBin(case$args$body$file, file)
      args <- case$args
      args$body$file <- curl::form_file(file)
      uploaded <- multipart(invoke(fn, args)$wire)
      expect_identical(uploaded$file$body, case$args$body$file)
    }
    # A malformed declared input must fail before the localhost server sees it.
    if (length(case$args)) {
      invalid <- case$args
      field <- if ('body' %in% names(invalid)) 'body' else names(invalid)[[1L]]
      invalid[[field]] <- if (field == 'body') 'invalid object' else list('invalid scalar')
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    if ('body' %in% names(case$args)) {
      invalid <- case$args
      if (case$body_media == 'multipart/form-data') {
        invalid$body$file <- '/a/plain/path/is/not/a/binary/upload'
      } else {
        property <- names(invalid$body)[[1L]]
        invalid$body[[property]] <- 1L
      }
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    if ('body' %in% names(case$args)) {
      invalid <- case$args
      if (case$body_media == 'application/json') {
        invalid$body <- NULL
      } else {
        invalid$body <- list(file = case$args$body$file)
      }
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    for (status in c(400L, 401L, 404L, 500L)) {
      response$status <- status
      response$body <- charToRaw('{"error":"webtest sentinel"}')
      saveRDS(response, file.path(directory, 'response.rds'))
      count <- count + 1L
      error <- tryCatch(do.call(fn, case$args), error = identity)
      expect_s3_class(error, if (status == 401L) 'specmill_call_error' else paste0('httr2_http_', status))
      if (status != 401L) {
        expect_identical(httr2::resp_status(error$resp), status)
        expect_identical(httr2::resp_body_string(error$resp), '{"error":"webtest sentinel"}')
      }
      expect_true(file.exists(file.path(directory, paste0(count, '.rds'))), info = name)
    }
    response$status <- 200L
    for (sample in list(
      list(media = 'image/svg+xml', body = charToRaw('<svg>sentinel</svg>'), value = '<svg>sentinel</svg>'),
      list(media = 'image/png', body = as.raw(c(137, 80, 78, 71, 0, 255)), value = as.raw(c(137, 80, 78, 71, 0, 255))),
      list(media = 'text/plain', body = charToRaw('report sentinel'), value = 'report sentinel'),
      list(media = 'application/json', body = charToRaw('{}'), value = stats::setNames(list(), character()))
    )) {
      response$media <- sample$media
      response$body <- sample$body
      saveRDS(response, file.path(directory, 'response.rds'))
      expect_identical(invoke(fn, case$args)$value, sample$value, info = name)
    }
    response$status <- 204L
    response$body <- raw()
    saveRDS(response, file.path(directory, 'response.rds'))
    expect_null(invoke(fn, case$args)$value)
    response$status <- 200L
    response$media <- 'application/json'
    response$body <- charToRaw('{')
    saveRDS(response, file.path(directory, 'response.rds'))
    count <- count + 1L
    expect_error(do.call(fn, case$args), 'Cannot decode')
    response$body <- charToRaw('{"ok":true,"items":[1,2]}')
    saveRDS(response, file.path(directory, 'response.rds'))
  }
  output <- Sys.getenv('COMPTOXR_WEBTEST_EVIDENCE')
  if (nzchar(output)) saveRDS(evidence, output, version = 2)
})

test_that('WebTEST exports preserve transport condition identity', {
  original <- structure(list(message = 'transport sentinel', call = NULL),
    class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition'))
  local_mocked_bindings(req_perform = function(...) stop(original), .package = 'httr2')
  for (name in names(webtest_export_cases())) {
    expect_identical(tryCatch(do.call(getExportedValue('ComptoxR', name),
      webtest_export_cases()[[name]]$args), error = identity), original)
  }
})
