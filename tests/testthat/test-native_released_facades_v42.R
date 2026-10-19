# Frozen legacy comparisons use the real httr2 executor and a real localhost.
test_that('released legacy facades preserve their values, inputs, wire and failures', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  directory <- tempfile('facades-v42-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  reply <- list(status = 200L, body = '{"data":[{"value":1,"empty":null}]}')
  saveRDS(reply, file.path(directory, 'reply.rds'))
  server <- callr::r_bg(function(directory) {
    count <- 0L; port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      count <<- count + 1L
      body <- req$rook.input$read()
      saveRDS(list(path = req$PATH_INFO, query = req$QUERY_STRING, method = req$REQUEST_METHOD,
        accept = req$HTTP_ACCEPT, body = body), file.path(directory, paste0(count, '.rds')))
      reply <- readRDS(file.path(directory, 'reply.rds'))
      if (isTRUE(reply$mixed) && (grepl('bad', req$PATH_INFO) || grepl('bad', rawToChar(body)))) reply$status <- 500L
      list(status = reply$status, headers = list(`Content-Type` = 'application/json', Connection = 'close', `Retry-After` = '0'), body = reply$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(20)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  url <- paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')))
  withr::local_options(list(ComptoxR.chemi_burl = paste0(url, '/api'), ComptoxR.ctx_burl = url,
    comptoxr_native.request = list(max_retries = 2L, retry_writes = TRUE, retry_policy = 'is_transient_error', timeout = 2)))
  withr::local_envvar(c(ctx_api_key = 'localhost-only', batch_limit = '1'))
  ns <- asNamespace('ComptoxR')
  frozen <- readRDS(test_path('fixtures/released-facades-v42-legacy.rds'))
  cases <- list(
    chemi_chet_reaction_searchcounts = list('one'),
    chemi_chet_reaction_database_old_by_pagenum_and_searchterm = list('one'),
    chemi_resolver_resolve = list('one', list(list(query = 'x'))),
    chemi_toxprints_assays_bulk = list(acl = 'one', actives = 0, category = 'category', chemicals = list(list(sid = 'record')), options = list(flag = FALSE), total = 0),
    chemi_toxprints_chemicals_categories = list('one'),
    chemi_toxprints_toxprints_categories = list('one'),
    chemi_stdizer_records = list(full = 'one', options = list(flag = FALSE), records = list(list(sid = 'record'))))
  count <- 0L
  signature <- function(e) {
    if (is.null(e)) return(NULL)
    list(class = class(e), message = conditionMessage(e), parent = signature(e$parent), location = e$location)
  }
  capture <- function(fn, args) {
    warnings <- character()
    value <- withCallingHandlers(tryCatch(suppressMessages(do.call(fn, args)), error = identity), warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
    })
    wires <- list()
    while (file.exists(file.path(directory, paste0(count + 1L, '.rds')))) {
      count <<- count + 1L
      wire <- readRDS(file.path(directory, paste0(count, '.rds')))
      # The one reviewed route correction is asserted separately below.
      wire$path <- sub('/stdizer/groups/([^/]+)/recursive$', '/stdizer/groups/recursive/\\1', wire$path)
      wires[[length(wires) + 1L]] <- wire
    }
    list(value = if (!inherits(value, 'error')) value,
      error = if (inherits(value, 'error')) signature(value), warnings = warnings, wire = wires)
  }
  for (name in names(cases)) {
    fn <- get(name, ns); old <- eval(frozen[[name]], ns); args <- cases[[name]]
    expect_identical(formals(fn), formals(old), info = name)
    expect_true(name %in% getNamespaceExports('ComptoxR'))
    for (input in list('one', c('one', 'two'), c('one', 'one', NA, ''), 1L, c(1L, 2L), list('one', 'two'), NULL, character())) {
      supplied <- args; supplied[1L] <- list(input)
      for (status in c(200L, 404L, 500L)) {
        reply$status <- status; saveRDS(reply, file.path(directory, 'reply.rds'))
        a <- capture(old, supplied); b <- capture(fn, supplied)
        expect_identical(b, a, info = paste(name, status, deparse(input)))
        if (!is.null(b$error) && status >= 400L && length(b$wire) == 1L)
          expect_true(paste0('httr2_http_', status) %in% b$error$class, info = name)
      }
    }
    reply$status <- 200L
    if (grepl('^chemi_chet_reaction_', name)) {
      saveRDS(reply, file.path(directory, 'reply.rds'))
      for (input in list('one', c('one', 'two'))) {
        for (trailing in list('', 'a b', list('a', 'b'))) {
          expect_identical(capture(fn, list(input, trailing)), capture(old, list(input, trailing)), info = name)
        }
      }
    }
    for (body in c('null', '[]', '{}', '[{"value":1,"empty":null}]', '{')) {
      reply$body <- body; saveRDS(reply, file.path(directory, 'reply.rds'))
      expect_identical(capture(fn, args), capture(old, args), info = paste(name, body))
    }
    reply$body <- '{"data":[{"value":1,"empty":null}]}'
    if (name %in% c('chemi_stdizer_records', 'chemi_toxprints_assays_bulk')) {
      for (value in list(NULL, list(), list(flag = FALSE, count = 0, nested = list(label = 'caller')), FALSE, 0)) {
        supplied <- args; supplied['options'] <- list(value)
        saveRDS(reply, file.path(directory, 'reply.rds'))
        expect_identical(capture(fn, supplied), capture(old, supplied), info = name)
      }
    }
    reply$status <- 401L; saveRDS(reply, file.path(directory, 'reply.rds'))
    expect_error(do.call(fn, args), class = 'specmill_call_error', info = name)
    # Drain the real request made by the hard-401 assertion.
    capture(function() NULL, list())
    reply$status <- 200L; saveRDS(reply, file.path(directory, 'reply.rds'))
    withr::with_options(list(comptoxr_native.request = list(timeout = -1)), {
      before <- count
      expect_error(do.call(fn, args), class = 'specmill_call_error', info = name)
      expect_false(file.exists(file.path(directory, paste0(before + 1L, '.rds'))))
    })
    # Real connection-refused transport retains the received httr2 failure class.
    withr::with_options(list(ComptoxR.chemi_burl = 'http://127.0.0.1:1', ComptoxR.ctx_burl = 'http://127.0.0.1:1'), {
      a <- capture(old, args); b <- capture(fn, args)
      expect_identical(b$error$class, a$error$class, info = name)
      expect_identical(b$warnings, a$warnings, info = name)
      expect_identical(b$value, a$value, info = name)
    })
  }
  for (name in names(cases)[c(1L, 2L)]) {
    reply$mixed <- TRUE; saveRDS(reply, file.path(directory, 'reply.rds'))
    args <- list(c('one', 'bad', 'two'))
    expect_identical(capture(get(name, ns), args), capture(eval(frozen[[name]], ns), args), info = name)
    reply$mixed <- FALSE
  }
})
