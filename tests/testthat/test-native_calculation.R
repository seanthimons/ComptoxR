calculation_names <- c('chemi_padel', 'chemi_padel_bulk', 'chemi_rdkit', 'chemi_rdkit_bulk',
  'chemi_webtest', 'chemi_webtest_bulk', 'chemi_descriptors', 'chemi_descriptors_bulk')

calculation_frozen <- function(name) {
  definitions <- readRDS(test_path('fixtures/native-calculation-contracts.rds'))
  eval(definitions[[name]][[3L]], asNamespace('ComptoxR'))
}
calculation_capture <- function(fn, args) {
  warnings <- character()
  value <- withCallingHandlers(tryCatch(do.call(fn, args), error = identity),
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning') })
  list(value = if (!inherits(value, 'error')) value,
    error = if (inherits(value, 'error')) list(class = if (inherits(value, 'missingArgError')) setdiff(class(value), c('evalError', 'getvarError')) else class(value), message = conditionMessage(value),
      location = value$location, parent = class(value$parent)), warnings = warnings)
}
calculation_args <- function(name, output = 'wide') {
  args <- list('CCO', output = output)
  if (grepl('rdkit', name)) args$bits <- 2L
  if (grepl('^chemi_descriptors', name)) args$type <- 'padel'
  args
}

test_that('native calculation facades preserve wire, values, warnings and parse errors', {
  withr::local_options(list(ComptoxR.chemi_burl = 'https://calculation.invalid/api'))
  requests <- list(); payload <- NULL; hooks <- list()
  original_hook <- get('run_hook', asNamespace('ComptoxR'))
  local_mocked_bindings(run_hook = function(name, stage, data) {
    hooks[[length(hooks) + 1L]] <<- list(name = name, stage = stage, data = data)
    original_hook(name, stage, data)
  }, .package = 'ComptoxR')
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- list(url = req$url, method = req$method,
      headers = req$headers, body = req$body)
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'), body = charToRaw(payload))
  }, .package = 'httr2')
  for (name in calculation_names) {
    old <- calculation_frozen(name); native <- get(name, asNamespace('ComptoxR'))
    expect_identical(formals(native), formals(old), info = name)
    for (payload in c('{"chemicals":[{"smiles":"CCO","descriptors":[1,2]}],"headers":["a","b"]}',
      '{"chemicals":[]}', '{"error":"calculation sentinel"}', 'null', '[]', '{')) {
      for (output in c('wide', 'raw')) {
        args <- calculation_args(name, output)
        requests <- hooks <- list(); expected <- calculation_capture(old, args); old_wire <- requests; old_hooks <- hooks
        requests <- hooks <- list(); actual <- calculation_capture(native, args)
        expect_identical(actual, expected, info = paste(name, output, payload))
        expect_identical(requests, old_wire, info = paste(name, output, payload))
        expect_identical(hooks, old_hooks, info = paste(name, output, payload))
      }
    }
    for (input in list(c(NA_character_, ''), character(), NULL, c('CCO','CCO','CCC'), 1L)) {
      args <- calculation_args(name); args[[1L]] <- input
      requests <- hooks <- list(); expected <- calculation_capture(old, args); old_wire <- requests; old_hooks <- hooks
      requests <- hooks <- list(); actual <- calculation_capture(native, args)
      expect_identical(actual, expected, info = name)
      expect_identical(requests, old_wire, info = name)
      expect_identical(hooks, old_hooks, info = name)
    }
  }
})

test_that('calculation HTTP and transport errors keep received conditions and hard 401', {
  withr::local_options(list(ComptoxR.chemi_burl = 'https://calculation.invalid/api'))
  for (name in calculation_names) {
    for (status in c(404L, 500L, 401L, 0L)) local({
      sentinel <- errorCondition('transport sentinel', class = 'httr2_failure')
      local_mocked_bindings(req_perform = function(req, ...) {
        if (!status) stop(sentinel)
        response <- httr2::response(status_code = status,
          headers = list(`Content-Type` = 'application/json'), body = charToRaw('{"error":"received"}'))
        policy <- req$policies$error_is_error
        if (is.null(policy) || isTRUE(policy(response))) httr2::resp_check_status(response)
        response
      }, .package = 'httr2')
      native <- get(name, asNamespace('ComptoxR')); args <- calculation_args(name)
      if (status == 401L) expect_error(do.call(native, args), class = 'specmill_call_error')
      else expect_identical(calculation_capture(native, args), calculation_capture(calculation_frozen(name), args), info = name)
    })
  }
})

test_that('WebTEST bulk keeps its CSV and TSV output contract', {
  withr::local_options(list(ComptoxR.chemi_burl = 'https://calculation.invalid/api'))
  for (format in c('CSV', 'TSV')) local({
    media <- if (format == 'CSV') 'text/csv' else 'text/tab-separated-values'
    separator <- if (format == 'CSV') ',' else '\t'
    payload <- paste0(paste(c('Ordinal','SMILES','a','b'), collapse = separator), '\n',
      paste(c('0','CCO','1','2'), collapse = separator), '\n')
    local_mocked_bindings(req_perform = function(req, ...) {
      expect_identical(req$headers$Accept, media)
      httr2::response(status_code = 200L, headers = list(`Content-Type` = media), body = charToRaw(payload))
    }, .package = 'httr2')
    for (output in c('wide','raw')) {
      args <- list('CCO', format = format, output = output)
      expect_identical(calculation_capture(chemi_webtest_bulk, args),
        calculation_capture(calculation_frozen('chemi_webtest_bulk'), args))
    }
  })
})

test_that('calculation facades preserve actual localhost wire and received HTTP errors', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  directory <- tempfile('calculation-wire-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(200L, file.path(directory, 'status.rds'))
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      saveRDS(list(method = request$REQUEST_METHOD, path = request$PATH_INFO,
        query = request$QUERY_STRING, accept = request$HTTP_ACCEPT, content_type = request$CONTENT_TYPE,
        body = request$rook.input$read()), file.path(directory, 'request.rds'))
      list(status = readRDS(file.path(directory, 'status.rds')),
        headers = list(`Content-Type` = 'application/json'),
        body = '{"chemicals":[{"smiles":"CCO","descriptors":[1,2]}],"headers":["a","b"]}')
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
  withr::local_options(list(ComptoxR.chemi_burl = paste0('http://127.0.0.1:',
    readRDS(file.path(directory, 'ready.rds')), '/api'),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  for (name in calculation_names) {
    args <- calculation_args(name); native <- get(name, asNamespace('ComptoxR'))
    saveRDS(200L, file.path(directory, 'status.rds'))
    expected <- calculation_capture(calculation_frozen(name), args)
    wire <- readRDS(file.path(directory, 'request.rds'))
    actual <- calculation_capture(native, args)
    expect_identical(actual, expected, info = name)
    expect_identical(readRDS(file.path(directory, 'request.rds')), wire, info = name)
    for (status in c(404L,500L,401L)) {
      saveRDS(status, file.path(directory, 'status.rds'))
      value <- tryCatch(do.call(native, args), error = identity)
      if (status == 401L) expect_s3_class(value, 'specmill_call_error')
      else {
        old <- tryCatch(do.call(calculation_frozen(name), args), error = identity)
        expect_identical(class(value), class(old), info = name)
        expect_s3_class(value, paste0('httr2_http_',status))
        expect_identical(httr2::resp_status(value$resp), status)
        expect_identical(httr2::resp_body_raw(value$resp), httr2::resp_body_raw(old$resp))
      }
    }
  }
})

test_that('invalid native request controls stop calculations before HTTP', {
  withr::local_options(list(comptoxr_native.request = list(max_retries = -1)))
  local_mocked_bindings(req_perform = function(...) stop('unexpected HTTP'), .package = 'httr2')
  for (name in calculation_names) expect_error(do.call(get(name, asNamespace('ComptoxR')),
    calculation_args(name)), class = 'specmill_call_error')
})

test_that('calculation facades preserve engine options and resolved bulk inputs', {
  withr::local_options(list(ComptoxR.chemi_burl = 'https://calculation.invalid/api'))
  requests <- list()
  local_mocked_bindings(chemi_resolver_lookup_bulk = function(ids, ...) {
    lapply(ids, function(id) list(result = 'FOUND', chemical = list(canonicalSmiles = 'CCO')))
  }, .package = 'ComptoxR')
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- list(url = req$url, headers = req$headers, body = req$body)
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'),
      body = charToRaw('{"chemicals":[{"smiles":"CCO","descriptors":[1,2]}],"headers":["a","b"]}'))
  }, .package = 'httr2')
  cases <- list(
    chemi_padel = list('CCO', x2d = FALSE, x3d = TRUE, fp = TRUE, headers = TRUE, timeout = 2),
    chemi_padel_bulk = list(c('CCO','CCO','CCC'), x2d = FALSE, x3d = TRUE, fp = TRUE, timeout = 2),
    chemi_rdkit = list('CCO', type = 'ecfp', radius = 2, bits = 2),
    chemi_rdkit_bulk = list(c('DTXSID7020182','DTXSID7020182'), options = list(type = 'ecfp',radius = 2,bits = 2)),
    chemi_webtest = list('DTXSID7020182', headers = TRUE),
    chemi_webtest_bulk = list(c('DTXSID7020182','DTXSID7020182'), chemIdType = 'DTXSID', headers = TRUE))
  for (name in names(cases)) {
    requests <- list(); old <- calculation_capture(calculation_frozen(name), cases[[name]]); old_wire <- requests
    requests <- list(); actual <- calculation_capture(get(name, asNamespace('ComptoxR')), cases[[name]])
    expect_identical(actual, old, info = name)
    expect_identical(requests, old_wire, info = name)
  }
})
