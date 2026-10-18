# Retained pending specmill#174. Real HTTP, frozen root functions, independent caches.
test_that('PubChem retained facades preserve actual requests, caches and Fault warnings', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  frozen <- readRDS(test_path('fixtures/pubchem-retained-originals.rds'))
  directory <- tempfile('pubchem-http-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(list(status = 200L, mode = 'success'), file.path(directory, 'control.rds'))
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    calls <- list()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      body <- rawToChar(request$rook.input$read())
      path <- request$PATH_INFO
      calls[[length(calls) + 1L]] <<- list(method = request$REQUEST_METHOD,
        path = path, body = body, media = request$CONTENT_TYPE)
      saveRDS(calls, file.path(directory, 'calls.rds'))
      control <- readRDS(file.path(directory, 'control.rds'))
      value <- if (control$mode == 'invalid') '{' else if (control$mode == 'missing') '{}' else
        if (control$mode == 'fault') '{"Fault":{"Code":"PUGREST.NotFound","Message":"sentinel"}}' else
          if (grepl('/cids/JSON$', path)) '{"IdentifierList":{"CID":[2244,6623]}}' else {
            cid <- if (request$REQUEST_METHOD == 'POST') {
              utils::URLdecode(sub('^cid=', '', body))
            } else sub('^/compound/cid/([^/]+)/.*$', '\\1', path)
            ids <- as.integer(strsplit(cid, ',', fixed = TRUE)[[1L]])
            if (grepl('/synonyms/JSON$', path)) {
              jsonlite::toJSON(list(InformationList = list(Information = lapply(ids, function(id)
                list(CID = id, Synonym = c('aspirin', 'ASA'))))), auto_unbox = TRUE)
            } else jsonlite::toJSON(list(PropertyTable = list(Properties = lapply(ids, function(id)
              list(CID = id, XLogP = 1.2)))), auto_unbox = TRUE)
          }
      list(status = control$status, headers = list(`Content-Type` = 'application/json'), body = value)
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
  withr::local_options(list(ComptoxR.pubchem_burl = paste0('http://127.0.0.1:',
    readRDS(file.path(directory, 'ready.rds'))), ComptoxR.run_verbose = FALSE))
  calls <- function() {
    if (file.exists(file.path(directory, 'calls.rds'))) readRDS(file.path(directory, 'calls.rds')) else list()
  }
  control <- function(mode = 'success', status = 200L)
    saveRDS(list(mode = mode, status = status), file.path(directory, 'control.rds'))
  make_client <- function(old) {
    env <- new.env(parent = asNamespace('ComptoxR'))
    env$.ComptoxREnv <- new.env(parent = emptyenv())
    for (name in names(frozen$functions)) assign(name, if (old)
      eval(frozen$functions[[name]], env) else if (is.function(get(name, asNamespace('ComptoxR')))) {
        fn <- get(name, asNamespace('ComptoxR'))
        environment(fn) <- env
        fn
      } else get(name, asNamespace('ComptoxR')), env)
    env
  }
  clients <- lapply(c(TRUE, FALSE), make_client)
  results <- lapply(clients, function(client) {
    start <- length(calls())
    search <- client$pubchem_search('aspirin')
    expect_identical(search$cid, c(2244L, 6623L))
    expect_identical(client$pubchem_search('aspirin'), search)
    expect_length(calls(), start + 1L)
    withr::with_options(list(ComptoxR.pubchem_burl = ''), {
      expect_identical(client$pubchem_search('aspirin'), search)
    })
    client$pubchem_search('C/C=C\\C#N', type = 'smiles', cache = FALSE)
    expect_identical(tail(calls(), 1L)[[1L]]$method, 'POST')
    expect_identical(tail(calls(), 1L)[[1L]]$body, 'smiles=C%2FC%3DC%5CC%23N')
    expect_identical(tail(calls(), 1L)[[1L]]$media, 'application/x-www-form-urlencoded')
    client$pubchem_search('a/b +#', type = 'name', cache = FALSE)
    expect_identical(tail(calls(), 1L)[[1L]]$method, 'GET')
    properties <- client$pubchem_properties(1L, properties = 'XLogP')
    mixed <- client$pubchem_properties(c(2L, 1L), properties = 'XLogP')
    expect_identical(mixed$CID, c(1L, 2L))
    expect_identical(tail(calls(), 1L)[[1L]]$path, '/compound/cid/2/property/XLogP/JSON')
    start <- length(calls())
    expect_identical(client$pubchem_properties(c(2L, 1L, 2L), properties = 'XLogP')$CID, c(2L, 1L, 2L))
    expect_length(calls(), start)
    batch <- client$pubchem_properties(1:150, properties = 'XLogP', cache = FALSE)
    expect_identical(batch$CID, 1:150)
    expect_length(calls(), start + 2L)
    expect_true(all(vapply(tail(calls(), 2L), function(x) x$method == 'POST', logical(1))))
    raw <- client$pubchem_synonyms(1L, tidy = FALSE)
    mixed_raw <- client$pubchem_synonyms(c(2L, 1L), tidy = FALSE)
    expect_identical(vapply(mixed_raw, `[[`, integer(1), 'CID'), c(1L, 2L))
    expect_identical(tail(calls(), 1L)[[1L]]$path, '/compound/cid/2/synonyms/JSON')
    start <- length(calls())
    tidy <- client$pubchem_synonyms(c(2L, 1L))
    expect_identical(tidy$cid, c(2L, 2L, 1L, 1L))
    expect_length(calls(), start)
    expect_error(client$pubchem_properties(stop('cid forced'), '../invalid', cache = stop('cache forced')),
      'Invalid PubChem property')
    expect_error(client$pubchem_search('', cache = stop('cache forced')), 'single non-empty')
    expect_error(client$pubchem_synonyms(NA_integer_, tidy = stop('tidy forced'),
      cache = stop('cache forced')), 'at least one valid integer')
    control('fault', 404L)
    missing_warnings <- character()
    empty <- withCallingHandlers(client$pubchem_search('missing'), warning = function(w) {
      missing_warnings <<- c(missing_warnings, conditionMessage(w))
      invokeRestart('muffleWarning')
    })
    expect_length(missing_warnings, 2L)
    expect_match(missing_warnings[[1L]], 'PUGREST.NotFound')
    expect_match(missing_warnings[[2L]], 'No PubChem CIDs found')
    # The first warning is the HTTP Fault; both are compared below without alteration.
    start <- length(calls())
    expect_silent(expect_identical(client$pubchem_search('missing'), empty))
    expect_length(calls(), start)
    conditions <- list()
    for (case in list(list('fault', 401L), list('fault', 200L), list('invalid', 200L), list('missing', 200L))) {
      control(case[[1L]], case[[2L]])
      warnings <- list()
      value <- withCallingHandlers(client$pubchem_synonyms(999L, tidy = FALSE, cache = FALSE),
        warning = function(w) { warnings[[length(warnings) + 1L]] <<- list(class = class(w),
          message = conditionMessage(w)); invokeRestart('muffleWarning') })
      expect_identical(value, list())
      expect_length(warnings, 1L)
      conditions[[length(conditions) + 1L]] <- list(value = value, warnings = warnings)
    }
    control()
    list(search = search, properties = properties, mixed = mixed, batch = batch,
      raw = raw, mixed_raw = mixed_raw, tidy = tidy, conditions = conditions)
  })
  expect_identical(results[[1L]], results[[2L]])
  for (name in c('pubchem_properties', 'pubchem_search', 'pubchem_synonyms')) {
    expect_identical(formals(get(name, clients[[1L]])), formals(get(name, clients[[2L]])))
  }
})
