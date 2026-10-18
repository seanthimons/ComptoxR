test_that('remaining safety facade preserves lazy inputs and uses the Chemical array body', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  directory <- tempfile('remaining-safety-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(list(status = 200L, body = '{"flags":[{"value":1}],"empty":null}'), file.path(directory, 'reply.rds'))
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      saveRDS(list(path = request$PATH_INFO, query = request$QUERY_STRING,
        method = request$REQUEST_METHOD, body = request$rook.input$read()), file.path(directory, 'request.rds'))
      reply <- readRDS(file.path(directory, 'reply.rds'))
      list(status = reply$status, headers = list(`Content-Type` = 'application/json'), body = reply$body)
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
  withr::local_options(list(ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  ns <- asNamespace('ComptoxR')
  frozen <- readRDS(test_path('fixtures/native-remaining-facades.rds'))
  old <- eval(frozen$legacy$chemi_resolver_safety_flags_bulk[[1L]][[3L]], ns)
  expect_identical(formals(chemi_resolver_safety_flags_bulk), formals(old))
  args <- list(additionalProps = list(source = 'test'), sid = 'DTXSID7020182', smiles = 'C=O', cid = '712', averageMass = 30)
  expect_identical(do.call(chemi_resolver_safety_flags_bulk, args), do.call(old, args))
  chemi_resolver_safety_flags_bulk(additionalProps = list(source = 'test'), sid = 'ONE', request.filesInfo = stop('ignored'))
  req <- readRDS(file.path(directory, 'request.rds'))
  expect_identical(req$path, '/api/resolver/safety-flags')
  expect_identical(req$method, 'POST')
  expect_identical(req$query, '')
  body <- jsonlite::fromJSON(rawToChar(req$body), simplifyVector = FALSE)
  expect_length(body, 1L)
  expect_identical(body[[1L]], list(sid = 'ONE', additionalProps = list(source = 'test')))
  expect_null(body[[1L]]$chemicals)
  expect_null(body[[1L]]$options)
  for (input in list(NULL, character(), '', NA_character_)) {
    before <- tryCatch(old(additionalProps = input), error = identity)
    after <- tryCatch(chemi_resolver_safety_flags_bulk(additionalProps = input), error = identity)
    expect_s3_class(after, 'error')
    expect_identical(class(after), class(before))
    expect_identical(conditionMessage(after), conditionMessage(before))
  }
  expect_error(chemi_resolver_safety_flags_bulk(additionalProps = stop('primary'), averageMass = stop('options first')), 'options first')
  expect_error(old(additionalProps = stop('primary'), averageMass = stop('options first')), 'options first')
  for (reply in list(list(status = 204L, body = ''), list(status = 200L, body = 'null'), list(status = 200L, body = '[]'), list(status = 200L, body = '{}'),
    list(status = 200L, body = '{'), list(status = 404L, body = '{"error":"received"}'),
    list(status = 500L, body = '{"error":"received"}'), list(status = 401L, body = '{}'))) {
    saveRDS(reply, file.path(directory, 'reply.rds'))
    capture <- function(fn) {
      warnings <- character()
      value <- withCallingHandlers(tryCatch(do.call(fn, args), error = identity), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
      })
      list(value = if (!inherits(value, 'error')) value,
        error = if (inherits(value, 'error')) list(class = class(value), message = conditionMessage(value)), warnings = warnings)
    }
    if (reply$status == 401L) {
      expect_error(do.call(chemi_resolver_safety_flags_bulk, args), class = 'specmill_call_error')
      expect_true('httr2_http_401' %in% capture(old)$error$class)
    } else expect_identical(capture(chemi_resolver_safety_flags_bulk), capture(old))
  }
  # Held generated group projections are exercised only against this localhost.
  saveRDS(list(status = 200L, body = '{"id":"local-group","empty":null}'), file.path(directory, 'reply.rds'))
  groups <- list(
    chemi_stdizer_groups_bulk = list(acl = list(owner = 'local', access = 'PRIVATE'), description = 'group', frozen = FALSE, operations = list()),
    chemi_alerts_groups_bulk = list(description = 'group', name = 'local', frozen = FALSE, logicType = 'AND', operations = list())
  )
  for (name in names(groups)) {
    saveRDS(list(status = 200L, body = '{"id":"local-group","empty":null}'), file.path(directory, 'reply.rds'))
    candidate <- eval(frozen$held[[name]][[1L]][[3L]], ns)
    reference <- eval(frozen$legacy[[name]][[1L]][[3L]], ns)
    expect_identical(formals(candidate), formals(reference))
    expect_identical(do.call(candidate, groups[[name]]), do.call(reference, groups[[name]]))
    do.call(candidate, groups[[name]])
    req <- readRDS(file.path(directory, 'request.rds'))
    expect_identical(req$method, 'POST')
    expect_identical(req$query, '')
    body <- jsonlite::fromJSON(rawToChar(req$body), simplifyVector = FALSE)
    expect_identical(body$description, 'group')
    expect_identical(body$frozen, FALSE)
    expect_identical(body$operations, list())
    expect_null(body$chemicals)
    expect_null(body$options)
    before <- tryCatch(reference(), error = identity)
    after <- tryCatch(candidate(), error = identity)
    expect_identical(class(after), class(before))
    expect_identical(conditionMessage(after), conditionMessage(before))
    if (name == 'chemi_stdizer_groups_bulk') {
      expect_error(candidate(acl = stop('primary'), description = stop('options first')), 'options first')
      expect_error(reference(acl = stop('primary'), description = stop('options first')), 'options first')
      candidate(acl = list(owner = 'local'), request.filesInfo = stop('ignored'), request.replace = stop('ignored'))
    } else {
      expect_error(candidate(description = stop('primary'), frozen = stop('options first')), 'options first')
      expect_error(reference(description = stop('primary'), frozen = stop('options first')), 'options first')
    }
    args <- groups[[name]]
    for (status in c(401L, 404L, 500L)) {
      saveRDS(list(status = status, body = '{"error":"received"}'), file.path(directory, 'reply.rds'))
      expect_identical(capture(candidate), capture(reference))
    }
  }

})
