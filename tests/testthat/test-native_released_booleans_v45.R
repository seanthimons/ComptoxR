testthat::test_that('released boolean bindings validate inputs and send exact native requests', {
  testthat::skip_if_not_installed('httpuv')
  testthat::skip_if_not_installed('callr')
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
  fns <- list(chemi_resolver_exportsimilaritylist, chemi_resolver_exportsimilaritymap, chemi_opera_file)
  bodies <- list(chemicals = list(list(chemical = list(smiles = 'CCO'), result = 'FOUND')))
  args <- list(list(format = 'JSON', body = bodies),
    list(format = 'JSON', sort = FALSE, showImage = TRUE, limit = 'All',
      body = list(chemicals = list(list(smiles = 'CCO')))),
    list(body = list(file = charToRaw('CCO ethanol\n'))))
  flags <- list('showImage', c('sort', 'showImage'), 'standardize')
  paths <- c('/api/resolver/exportsimilaritylist', '/api/resolver/exportsimilaritymap', '/api/opera/file')
  count <- 0L
  for (i in seq_along(fns)) {
    for (value in c(FALSE, TRUE)) {
      a <- args[[i]]
      a[flags[[i]]] <- rep(list(value), length(flags[[i]]))
      testthat::expect_type(do.call(fns[[i]], a), 'list')
      count <- count + 1L
      wire <- readRDS(file.path(directory, paste0(count, '.rds')))
      query <- sub('^\\?', '', wire$query)
      testthat::expect_identical(wire$method, 'POST')
      testthat::expect_identical(wire$path, paths[[i]])
      for (flag in flags[[i]]) testthat::expect_match(query,
        paste0('(^|&)', flag, '=', tolower(value), '(&|$)'))
      if (i %in% c(1L, 2L)) testthat::expect_identical(
        jsonlite::fromJSON(rawToChar(wire$body), simplifyVector = FALSE), a$body)
      if (i == 3L) {
        testthat::expect_match(wire$content_type, '^multipart/form-data; boundary=')
        testthat::expect_match(rawToChar(wire$body), 'CCO ethanol\n', fixed = TRUE)
      }
    }
    for (flag in flags[[i]]) for (value in list('false', 1, NA, c(TRUE, FALSE), list(FALSE))) {
      a <- args[[i]]
      a[flag] <- list(value)
      testthat::expect_error(do.call(fns[[i]], a))
      testthat::expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
    }
    local({
      withr::local_envvar(chemi_burl = NA)
      withr::local_options(list(ComptoxR.chemi_burl = NULL, comptoxr_native.dry_run = TRUE))
      request <- do.call(fns[[i]], args[[i]])
      testthat::expect_identical(sub('[?].*$', '', request$url),
        paste0('https://hcd.rtpnc.epa.gov', paths[[i]]))
    })
  }
  for (status in c(400L, 404L, 500L, 401L)) {
    reply$status <- status
    saveRDS(reply, file.path(directory, 'reply.rds'))
    for (i in seq_along(fns)) {
      error <- tryCatch(do.call(fns[[i]], args[[i]]), error = identity)
      count <- count + 1L
      if (status == 401L) testthat::expect_s3_class(error, 'specmill_call_error') else {
        testthat::expect_s3_class(error, paste0('httr2_http_', status))
        testthat::expect_identical(httr2::resp_body_raw(error$resp), reply$body)
      }
    }
  }
})


testthat::test_that('regenerated scalar boolean metadata encodes existing GET bindings', {
  cases <- list(
    list(fn = chemi_opera, args = list(smiles = 'CCO'), flag = 'standardize'),
    list(fn = chemi_toxprints, args = list(smiles = 'CCO'), flag = 'headers'),
    list(fn = chemi_resolver_lookup, args = list(query = 'ethanol'), flag = 'mol'),
    list(fn = epi_ecosar_surfactant_nonionic, args = list(mainCarbons = 12L), flag = 'useSmiles'))
  frozen <- readRDS(testthat::test_path('fixtures/native-boolean-formals-v45.rds'))
  for (name in names(frozen)) testthat::expect_identical(formals(get(name)), frozen[[name]])
  request <- NULL
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    request <<- req
    body <- if (grepl('/ecosar/', req$url, fixed = TRUE)) '{"result":{"value":0}}' else '[{"id":"one"}]'
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'),
      body = charToRaw(body))
  }, .package = 'httr2')
  for (case in cases) for (value in c(FALSE, TRUE)) {
    args <- case$args
    args[case$flag] <- list(value)
    do.call(case$fn, args)
    testthat::expect_identical(httr2::url_parse(request$url)$query[[case$flag]], tolower(value))
  }
})
