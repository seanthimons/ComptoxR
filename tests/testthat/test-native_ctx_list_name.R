test_that('list-name combined hooks preserve all thirty frozen PR163 cases', {
  withr::local_options(list(cli.width = 1000, cli.unicode = FALSE, cli.num_colors = 1, width = 1000))
  withr::local_envvar(ctx_api_key = 'local-key')
  ns <- asNamespace('ComptoxR')
  legacy <- eval(readRDS(test_path('fixtures/native-ctx-list-name.rds'))$legacy, ns)
  requests <- trace <- list()
  original_hook <- get('run_hook', ns)
  local_mocked_bindings(run_hook = function(name, stage, data) {
    trace[[length(trace) + 1L]] <<- list(stage = stage, params = data$params)
    original_hook(name, stage, data)
  }, .package = 'ComptoxR')
  body <- ''
  local_mocked_bindings(req_perform = function(req, ...) {
    expect_identical(req$headers$Accept, 'application/json')
    expect_identical(httr2::req_get_headers(req, redacted = 'reveal')[['x-api-key']], 'local-key')
    requests[[length(requests) + 1L]] <<- req$url
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = 'application/json'), body = charToRaw(body))
  }, .package = 'httr2')
  invoke <- function(fn, ids, extract) {
    requests <<- trace <<- list()
    warnings <- character()
    value <- withCallingHandlers(tryCatch(
      fn(ids, projection = 'chemicallistwithdtxsids', extract_dtxsids = extract),
      error = identity), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
      })
    list(value = value, requests = requests, trace = trace, warnings = warnings)
  }
  baseline <- readRDS(test_path('fixtures/native-ctx-list-name.rds'))$baseline
  expect_identical(baseline$version, '1.7.0')
  comparisons <- 0L
  for (json in c('{"dtxsids":"SAME"}', '{"other":1}', '{bad')) {
    body <- json
    for (ids in list(c('LIST_A', 'LIST_B'), c('LIST_A', 'LIST_A', '', NA, 'LIST_B'),
      'LIST_A', character(), c('', NA))) {
      for (extract in c(TRUE, FALSE)) {
        old <- invoke(legacy, ids, extract)
        new <- invoke(ct_chemical_list_search_by_name, ids, extract)
        if (inherits(old$value, 'error')) {
          expect_identical(class(new$value), class(old$value))
          expect_identical(conditionMessage(new$value), conditionMessage(old$value))
          expect_identical(class(new$value$parent), class(old$value$parent))
        } else expect_identical(new$value, old$value)
        expect_identical(new$requests, old$requests)
        expect_identical(new$trace, old$trace)
        expect_identical(new$warnings, old$warnings)
        comparisons <- comparisons + 1L
        recorded <- new
        if (inherits(recorded$value, 'error')) recorded$value <- list(
          error_class = class(new$value), message = conditionMessage(new$value),
          parent_class = class(new$value$parent))
        expect_identical(recorded, baseline$records[[comparisons]])
      }
    }
  }
  expect_identical(comparisons, 30L)
})

test_that('list-name invokes the combined hook once with original parameters', {
  ids <- c('LIST_A', 'LIST_A', '', NA, 'LIST_B')
  withr::local_options(list(cli.width = 1000, cli.unicode = FALSE, cli.num_colors = 1, width = 1000))
  withr::local_envvar(ctx_api_key = 'local-key')
  calls <- 0L
  local_mocked_bindings(req_perform = function(req, ...) {
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = 'application/json'), body = charToRaw('{"dtxsids":"SAME"}'))
  }, .package = 'httr2')
  sentinel <- simpleError('hook boundary sentinel')
  local_mocked_bindings(run_hook = function(name, stage, data) {
    calls <<- calls + 1L
    expect_identical(stage, 'post_response')
    expect_identical(data$params$listName, ids)
    expect_s3_class(data$result, 'tbl_df')
    expect_equal(nrow(data$result), 2L)
    stop(sentinel)
  }, .package = 'ComptoxR')
  expect_identical(tryCatch(ct_chemical_list_search_by_name(ids), error = identity), sentinel)
  expect_identical(calls, 1L)
})

test_that('list-name real localhost requests preserve collection and status behavior', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  directory <- tempfile('list-name-http-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(200L, file.path(directory, 'status.rds'))
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      cat(request$REQUEST_METHOD, request$PATH_INFO, request$QUERY_STRING,
        '\n', file = file.path(directory, 'requests'), append = TRUE)
      saveRDS(list(accept = request$HTTP_ACCEPT, key = request$HTTP_X_API_KEY),
        file.path(directory, 'headers.rds'))
      list(status = readRDS(file.path(directory, 'status.rds')),
        headers = list(`Content-Type` = 'application/json'), body = '{"dtxsids":"SAME"}')
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
  withr::local_options(list(
    ComptoxR.ctx_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  withr::local_options(list(cli.width = 1000, cli.unicode = FALSE, cli.num_colors = 1, width = 1000))
  withr::local_envvar(ctx_api_key = 'local-key')
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  legacy <- eval(readRDS(test_path('fixtures/native-ctx-list-name.rds'))$legacy,
    asNamespace('ComptoxR'))
  ids <- c('LIST_A', 'LIST_A', '', NA, 'LIST_B')
  invoke <- function(fn, query) {
    warnings <- character()
    value <- withCallingHandlers(tryCatch(fn(query, projection = 'chemicallistwithdtxsids',
      extract_dtxsids = TRUE), error = identity), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
      })
    list(value = value, warnings = warnings)
  }
  expect_identical(invoke(ct_chemical_list_search_by_name, ids), invoke(legacy, ids))
  paths <- readLines(file.path(directory, 'requests'))
  expect_identical(readRDS(file.path(directory, 'headers.rds')),
    list(accept = 'application/json', key = 'local-key'))
  expect_length(paths, 4L)
  expect_identical(paths[1:2], paths[3:4])
  expect_match(paths[[1L]], 'GET /chemical/list/search/by-name/LIST_A ?projection=chemicallistwithdtxsids', fixed = TRUE)
  for (status in c(404L, 500L)) {
    saveRDS(status, file.path(directory, 'status.rds'))
    for (query in list('LIST_A', ids)) {
      old <- invoke(legacy, query); new <- invoke(ct_chemical_list_search_by_name, query)
      expect_identical(new$warnings, old$warnings)
      if (inherits(old$value, 'error')) {
        expect_identical(class(new$value), class(old$value))
        expect_identical(conditionMessage(new$value), conditionMessage(old$value))
      } else expect_identical(new$value, old$value)
    }
  }
  saveRDS(401L, file.path(directory, 'status.rds'))
  for (query in list('LIST_A', ids)) {
    expect_s3_class(invoke(ct_chemical_list_search_by_name, query)$value, 'specmill_call_error')
  }
})

test_that('list-name preserves a single transport condition before hooks', {
  withr::local_envvar(ctx_api_key = 'local-key')
  sentinel <- simpleError('transport boundary sentinel')
  local_mocked_bindings(req_perform = function(...) stop(sentinel), .package = 'httr2')
  local_mocked_bindings(run_hook = function(...) stop('hook reached after transport failure'),
    .package = 'ComptoxR')
  expect_identical(tryCatch(ct_chemical_list_search_by_name('LIST_A'), error = identity), sentinel)
})
