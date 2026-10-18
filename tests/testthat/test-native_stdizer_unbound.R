stdizer_unbound_wrappers <- c(
  'chemi_stdizer_groups_by_id_delete',
  'chemi_stdizer_groups_by_id_put',
  'chemi_stdizer_groups_by_id_acl_put',
  'chemi_stdizer_protocol_export_post',
  'chemi_stdizer_protocols',
  'chemi_stdizer_protocols_post',
  'chemi_stdizer_protocols_check',
  'chemi_stdizer_protocols_by_id_delete',
  'chemi_stdizer_protocols_by_id_patch',
  'chemi_stdizer_protocols_by_id_put',
  'chemi_stdizer_protocols_by_id_acl_put',
  'chemi_stdizer_protocols_by_id_changes',
  'chemi_stdizer_protocols_by_id_export_post',
  'chemi_stdizer_protocols_by_id_issues',
  'chemi_stdizer_render')

test_that('standardizer bindings validate inputs and preserve actual localhost wire contracts', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  cases <- readRDS(test_path('fixtures/native-stdizer-unbound.rds'))
  expect_setequal(names(cases), stdizer_unbound_wrappers)
  expect_true(all(stdizer_unbound_wrappers %in% getNamespaceExports('ComptoxR')))
  directory <- tempfile('stdizer-http-')
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
      # Close fixture responses so a changing 204 response cannot poison a pooled connection.
      list(status = result$status, headers = list(`Content-Type` = result$media, Connection = 'close'),
        body = if (result$status == 204L) NULL else result$body)
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
    value <- tryCatch(do.call(fn, args), error = function(error) {
      stop(paste(conditionMessage(error), server$read_error(),
        if (!is.null(error$parent)) conditionMessage(error$parent) else ''), call. = FALSE)
    })
    list(value = value, wire = readRDS(file.path(directory, paste0(count, '.rds'))))
  }
  for (name in names(cases)) {
    case <- cases[[name]]
    fn <- get(name, asNamespace('ComptoxR'))
    if (file.exists(test_path('..', '..', 'specmill.yml'))) {
      expect_identical(digest::digest(file = test_path('../..', case$source), algo = 'sha256'), case$source_sha256)
    }
    result <- invoke(fn, case$args)
    expect_identical(result$value, list(ok = TRUE, items = list(1L, 2L)), info = name)
    expect_identical(result$wire$method, case$method, info = name)
    expect_identical(result$wire$path, case$path, info = name)
    expect_identical(result$wire$accept, '*/*', info = name)
    query <- httr2::url_parse(paste0('http://localhost/?', sub('^\\?', '', result$wire$query)))$query
    expected <- lapply(case$query, function(x) if (is.logical(x)) tolower(as.character(x)) else as.character(x))
    expect_equal(query, if (length(expected)) expected else NULL, info = name)
    if (is.null(case$body_media)) {
      expect_length(result$wire$body, 0L)
    } else if (case$body_media == 'application/json') {
      expect_match(result$wire$content_type, '^application/json', info = name)
      expect_identical(jsonlite::fromJSON(rawToChar(result$wire$body), simplifyVector = FALSE), case$args$body, info = name)
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
      property <- switch(name,
        chemi_stdizer_records_post_native = 'options',
        chemi_stdizer_protocols_by_id_patch = 'curationStatus',
        names(invalid$body)[[1L]])
      invalid$body[[property]] <- 1L
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    if ('body' %in% names(case$args)) {
      invalid <- case$args
      invalid$body <- NULL
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    if ('width' %in% names(case$args)) for (bad in list(list(width = 1.5), list(format = 'JPEG'))) {
      invalid <- utils::modifyList(case$args, bad)
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    for (status in c(400L, 401L, 404L, 500L)) {
      response$status <- status
      response$body <- charToRaw('{"error":"stdizer sentinel"}')
      saveRDS(response, file.path(directory, 'response.rds'))
      count <- count + 1L
      error <- tryCatch(do.call(fn, case$args), error = identity)
      expect_s3_class(error, if (status == 401L) 'specmill_call_error' else 'simpleError')
      expect_match(conditionMessage(error), paste0('HTTP ', status, ' application/json'), info = name)
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
    response$media <- 'application/json'
    response$body <- charToRaw('{')
    saveRDS(response, file.path(directory, 'response.rds'))
    count <- count + 1L
    expect_error(do.call(fn, case$args), 'Cannot decode HTTP 200 application/json response as JSON', fixed = TRUE)
    response$status <- 204L
    response$body <- raw()
    saveRDS(response, file.path(directory, 'response.rds'))
    expect_null(invoke(fn, case$args)$value)
    response$status <- 200L
    response$media <- 'application/json'
    response$body <- charToRaw('{"ok":true,"items":[1,2]}')
    saveRDS(response, file.path(directory, 'response.rds'))
  }
})
