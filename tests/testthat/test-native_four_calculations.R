four_calculation_names <- c('chemi_mordred', 'chemi_mordred_bulk',
  'chemi_webtest_predict', 'chemi_webtest_predict_bulk')

four_calculation_frozen <- function(name) {
  definitions <- readRDS(test_path('fixtures/native-four-calculations-contracts.rds'))
  eval(definitions[[name]][[3L]], asNamespace('ComptoxR'))
}
four_calculation_capture <- function(fn, args) {
  warnings <- character()
  value <- withCallingHandlers(tryCatch(do.call(fn, args), error = identity),
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning') })
  list(value = if (!inherits(value, 'error')) value,
    error = if (inherits(value, 'error')) list(class = class(value), message = conditionMessage(value),
      location = value$location, parent = class(value$parent)), warnings = warnings)
}
four_calculation_args <- function(name, output = 'wide') {
  args <- list('CCO', output = output)
  if (grepl('predict', name)) args[[if (grepl('_bulk$', name)) 'endpoints' else 'endpoint']] <- 'LC50'
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
  for (name in four_calculation_names) {
    old <- four_calculation_frozen(name); native <- get(name, asNamespace('ComptoxR'))
    expect_identical(formals(native), formals(old), info = name)
    for (payload in c('{"chemicals":[{"smiles":"CCO","descriptors":[1,2]}],"headers":["a","b"]}',
      jsonlite::toJSON(list(chemicals = list(webtest_contract_prediction(smiles = 'CCO'))), auto_unbox = TRUE),
      '{"chemicals":[]}', '{"error":"calculation sentinel"}', 'null', '[]', '{')) {
      for (output in c('wide', 'raw')) {
        args <- four_calculation_args(name, output)
        requests <- hooks <- list(); expected <- four_calculation_capture(old, args); old_wire <- requests; old_hooks <- hooks
        requests <- hooks <- list(); actual <- four_calculation_capture(native, args)
        expect_identical(actual, expected, info = paste(name, output, payload))
        expect_identical(requests, old_wire, info = paste(name, output, payload))
        expect_identical(hooks, old_hooks, info = paste(name, output, payload))
      }
    }
    for (input in list(c(NA_character_, ''), character(), NULL, c('CCO','CCO','CCC'), 1L)) {
      args <- four_calculation_args(name); args[[1L]] <- input
      requests <- hooks <- list(); expected <- four_calculation_capture(old, args); old_wire <- requests; old_hooks <- hooks
      requests <- hooks <- list(); actual <- four_calculation_capture(native, args)
      expect_identical(actual, expected, info = name)
      expect_identical(requests, old_wire, info = name)
      expect_identical(hooks, old_hooks, info = name)
    }
  }
})

test_that('calculation HTTP and transport errors keep received conditions and hard 401', {
  withr::local_options(list(ComptoxR.chemi_burl = 'https://calculation.invalid/api'))
  for (name in four_calculation_names) {
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
      native <- get(name, asNamespace('ComptoxR')); args <- four_calculation_args(name)
      if (status == 401L) expect_error(do.call(native, args), class = 'specmill_call_error')
      else expect_identical(four_calculation_capture(native, args), four_calculation_capture(four_calculation_frozen(name), args), info = name)
    })
  }
})

test_that('calculation facades preserve actual localhost wire and received HTTP errors', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  directory <- tempfile('calculation-wire-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(200L, file.path(directory, 'status.rds'))
  saveRDS('{}', file.path(directory, 'payload.rds'))
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      saveRDS(list(method = request$REQUEST_METHOD, path = request$PATH_INFO,
        query = request$QUERY_STRING, accept = request$HTTP_ACCEPT, content_type = request$CONTENT_TYPE,
        body = request$rook.input$read()), file.path(directory, 'request.rds'))
      list(status = readRDS(file.path(directory, 'status.rds')),
        headers = list(`Content-Type` = 'application/json'),
        body = readRDS(file.path(directory, 'payload.rds')))
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
  withr::local_options(list(ComptoxR.chemi_burl = paste0('http://127.0.0.1:',
    readRDS(file.path(directory, 'ready.rds')), '/api'),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  for (name in four_calculation_names) {
    args <- four_calculation_args(name); native <- get(name, asNamespace('ComptoxR'))
    payload <- if (grepl('predict', name)) {
      jsonlite::toJSON(list(chemicals = list(webtest_contract_prediction(smiles = 'CCO'))), auto_unbox = TRUE)
    } else '{"chemicals":[{"smiles":"CCO","descriptors":[null,2]}],"headers":["a","b"]}'
    saveRDS(as.character(payload), file.path(directory, 'payload.rds'))
    saveRDS(200L, file.path(directory, 'status.rds'))
    expected <- four_calculation_capture(four_calculation_frozen(name), args)
    wire <- readRDS(file.path(directory, 'request.rds'))
    actual <- four_calculation_capture(native, args)
    expect_identical(actual, expected, info = name)
    expect_null(actual$error, info = name)
    expect_true(nrow(actual$value) > 0L, info = name)
    expect_identical(readRDS(file.path(directory, 'request.rds')), wire, info = name)
    for (status in c(404L,500L,401L)) {
      saveRDS(status, file.path(directory, 'status.rds'))
      value <- tryCatch(do.call(native, args), error = identity)
      if (status == 401L) expect_s3_class(value, 'specmill_call_error')
      else {
        old <- tryCatch(do.call(four_calculation_frozen(name), args), error = identity)
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
  for (name in four_calculation_names) expect_error(do.call(get(name, asNamespace('ComptoxR')),
    four_calculation_args(name)), class = 'specmill_call_error')
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
    chemi_mordred = list('CCO', headers = FALSE, inchi = TRUE),
    chemi_mordred_bulk = list(c('DTXSID7020182','DTXSID7020182'), options = list(ignore_3D = TRUE), headers = TRUE, inchi = FALSE),
    chemi_webtest_predict = list('DTXSID7020182', endpoint = 'LC50', method = 'hc'),
    chemi_webtest_predict_bulk = list(c('CCO','CCC','CCO'), endpoints = c('LC50','LD50'), methods = c('hc','nn')))

  for (name in names(cases)) {
    requests <- list(); old <- four_calculation_capture(four_calculation_frozen(name), cases[[name]]); old_wire <- requests
    requests <- list(); actual <- four_calculation_capture(get(name, asNamespace('ComptoxR')), cases[[name]])
    expect_identical(actual, old, info = name)
    expect_identical(requests, old_wire, info = name)
  }
})

test_that('native hook lifecycle keeps private state, partial updates and skips', {
  withr::local_options(list(ComptoxR.chemi_burl = 'https://calculation.invalid/api'))
  original <- get('run_hook', asNamespace('ComptoxR'))
  requests <- list(); skip <- FALSE
  local_mocked_bindings(run_hook = function(name, stage, data) {
    if (stage == 'post_response') return(data)
    state <- original(name, stage, data)
    state$params <- list(output = 'raw', .private = list(sentinel = 17L))
    state$.private <- list(sentinel = 'preserve')
    if (skip) { state$skip_request <- TRUE; state$result <- list(skipped = TRUE) }
    state
  }, .package = 'ComptoxR')
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- list(url = req$url, method = req$method, body = req$body)
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'),
      body = charToRaw('{"chemicals":[]}'))
  }, .package = 'httr2')
  for (name in four_calculation_names) for (skip in c(FALSE, TRUE)) {
    requests <- list(); old <- four_calculation_capture(four_calculation_frozen(name), four_calculation_args(name))
    wire <- requests
    requests <- list(); actual <- four_calculation_capture(get(name, asNamespace('ComptoxR')), four_calculation_args(name))
    expect_identical(actual, old, info = name)
    expect_identical(requests, wire, info = name)
    expect_identical(actual$value$.private, list(sentinel = 'preserve'))
    expect_identical(actual$value$params$.private, list(sentinel = 17L))
    if (skip) { expect_length(requests, 0L); expect_identical(actual$value$result, list(skipped = TRUE)) }
  }
})

test_that('archived production Mordred rows survive and malformed predictions stay rejected', {
  archive <- readRDS(test_path('fixtures/native-four-calculations-production.rds'))
  for (name in four_calculation_names) local({
    evidence <- archive$results[[name]]
    response <- evidence$responses[[1L]]
    local_mocked_bindings(req_perform = function(req, ...) httr2::response(
      status_code = response$status, headers = list(`Content-Type` = response$media),
      body = response$body), .package = 'httr2')
    native <- get(name, asNamespace('ComptoxR'))
    for (output in c('wide','raw')) {
      args <- evidence$args; args$output <- output
      actual <- four_calculation_capture(native, args)
      expect_identical(actual, four_calculation_capture(four_calculation_frozen(name), args), info = name)
      if (grepl('mordred', name)) {
        expect_null(actual$error)
        if (output == 'wide') {
          expect_identical(nrow(actual$value), 1L)
          expect_identical(ncol(actual$value) - 10L, 1613L)
          expect_identical(sum(vapply(actual$value[-seq_len(10L)], function(x) all(is.na(x)), FALSE)), 385L)
          expect_identical(actual$value$status, 'ok')
        }
      } else if (output == 'wide') {
        expect_contains(actual$error$class, 'comptoxr_post_response_hook_error')
        expect_match(actual$error$message, 'endpoint is missing its endpoint id', fixed = TRUE)
      } else {
        expect_null(actual$error)
        body <- jsonlite::fromJSON(rawToChar(response$body), simplifyVector = FALSE)
        expect_identical(actual$value[names(body)], body)
      }
    }
  })
})
