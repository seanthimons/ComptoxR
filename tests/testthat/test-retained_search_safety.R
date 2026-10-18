test_that('search keeps transport-only all_pages lazy and preserves full skip state', {
  stages <- list()
  state <- list(params = list(query = 'partial'), request = list(body = 'kept'),
    marker = structure('kept', class = 'sentinel'), skip_request = TRUE, result = 'skip')
  local_mocked_bindings(run_hook = function(name, stage, data) {
    stages[[length(stages) + 1L]] <<- list(stage = stage, data = data)
    if (stage == 'pre_request') return(state)
    data
  }, generic_chemi_request = function(...) stop('transport must be skipped'))
  result <- chemi_search(all_pages = stop('all_pages forced on skip'))
  expect_identical(vapply(stages, `[[`, '', 'stage'), c('pre_request', 'post_response'))
  expect_identical(names(stages[[1L]]$data$params), setdiff(names(formals(chemi_search)), 'all_pages'))
  expect_identical(result, state)
  state$result <- NULL
  stages <- list()
  result <- chemi_search(all_pages = stop('all_pages forced on NULL skip'))
  expect_identical(result, state)
  expect_false('result' %in% names(result))
})

test_that('search transport uses original all_pages and preserves partial returned params', {
  request <- NULL
  post <- NULL
  state <- list(params = list(query = 'changed', all_pages = FALSE),
    request = list(body = list(searchType = 'MASS'), options = list(limit = 1)), marker = 2)
  local_mocked_bindings(run_hook = function(name, stage, data) {
    if (stage == 'pre_request') return(state)
    post <<- data
    data$result
  }, generic_chemi_request = function(...) { request <<- list(...); list(answer = 1) })
  expect_identical(chemi_search(all_pages = TRUE), list(answer = 1))
  expect_identical(request, list(endpoint = 'search', body = state$request$body,
    options = state$request$options, tidy = FALSE, paginate = TRUE, max_pages = 100,
    pagination_strategy = 'offset_limit'))
  state$result <- list(answer = 1)
  expect_identical(post, state)
})

test_that('safety retains its zero-input error before HTTP and formatter conditions', {
  calls <- 0L
  local_mocked_bindings(req_perform = function(...) { calls <<- calls + 1L; stop('unexpected HTTP') }, .package = 'httr2')
  expect_identical(formals(chemi_safety_rqcodes), NULL)
  expect_error(chemi_safety_rqcodes(), 'Either query or chemicals parameter must be provided', class = 'rlang_error')
  expect_identical(calls, 0L)
  payload <- list(list(rqCode = list(sid = 'one', rq = '1,000 (454)', category = 'A')))
  helper_calls <- 0L
  local_mocked_bindings(generic_chemi_request = function(...) {
    helper_calls <<- helper_calls + 1L
    expect_identical(list(...), list(query = NULL, endpoint = 'safety/rqcodes', tidy = FALSE))
    payload
  })
  expect_identical(chemi_safety_rqcodes(), tibble::tibble(sid = 'one', rq_lbs = 1000,
    rq_kgs = 454, category = 'A'))
  payload <- list(list(chemical = list(sid = 'one')), list(rqCode = NULL))
  expect_null(chemi_safety_rqcodes())
  payload <- list(list(rqCode = list(rq = 'bad units extra')))
  expect_error(chemi_safety_rqcodes(), class = 'rlang_error')
  payload <- list(list(rqCode = list(rq = 'bad (bad)')))
  expect_warning(value <- chemi_safety_rqcodes(), 'NAs introduced by coercion')
  expect_true(all(is.na(value$rq_lbs)))
  expect_identical(helper_calls, 4L)
  expect_identical(calls, 0L)
})

test_that('search localhost requests preserve paging, partial failures and condition stages', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  directory <- tempfile('search-facade-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    calls <- 0L
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      if (file.exists(file.path(directory, 'reset'))) {
        calls <<- 0L; unlink(file.path(directory, 'reset'))
      }
      calls <<- calls + 1L
      saveRDS(list(method = request$REQUEST_METHOD, path = request$PATH_INFO,
        content_type = request$CONTENT_TYPE, body = rawToChar(request$rook.input$read())),
        file.path(directory, paste0('request-', calls, '.rds')))
      scenario <- readRDS(file.path(directory, 'scenario.rds'))
      response <- scenario[[min(calls, length(scenario))]]
      list(status = response$status, headers = list(`Content-Type` = 'application/json'), body = response$body)
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
    readRDS(file.path(directory, 'ready.rds'))), comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  original_hook <- run_hook
  stages <- character()
  local_mocked_bindings(run_hook = function(name, stage, data) {
    stages <<- c(stages, stage)
    original_hook(name, stage, data)
  })
  invoke <- function(scenario, all_pages = FALSE) {
    unlink(list.files(directory, pattern = '^request-', full.names = TRUE))
    saveRDS(scenario, file.path(directory, 'scenario.rds'))
    file.create(file.path(directory, 'reset'))
    stages <<- character()
    warnings <- character()
    value <- withCallingHandlers(tryCatch(suppressMessages(chemi_search(search_type = 'mass',
      mass_type = 'mono', min_mass = 100, max_mass = 101, limit = 1, all_pages = all_pages)),
      error = identity), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
      })
    requests <- lapply(list.files(directory, pattern = '^request-', full.names = TRUE), readRDS)
    list(value = value, requests = requests, stages = stages, warnings = warnings)
  }
  page <- function(offset, total = 2L) list(status = 200L, body = jsonlite::toJSON(list(
    totalRecordsCount = total, recordsCount = 1L, offset = offset,
    records = list(list(sid = paste0('sid', offset)))), auto_unbox = TRUE))
  single <- invoke(list(page(0)))
  expect_identical(single$value, tibble::tibble(sid = 'sid0'))
  expect_identical(single$stages, c('pre_request', 'post_response'))
  expect_length(single$requests, 1L)
  expect_identical(single$requests[[1L]]$method, 'POST')
  expect_identical(single$requests[[1L]]$path, '/search')
  expect_match(single$requests[[1L]]$content_type, 'application/json')
  first <- jsonlite::fromJSON(single$requests[[1L]]$body, simplifyVector = FALSE)
  expect_identical(first$searchType, 'MASS')
  expect_identical(first$params[['mass-type']], 'monoisotopic-mass')
  expect_equal(first$params[['min-mass']], 100)
  expect_null(first$offset)
  paged <- invoke(list(page(0), page(1)), TRUE)
  expect_length(paged$requests, 2L)
  expect_identical(paged$stages, c('pre_request', 'post_response'))
  second <- jsonlite::fromJSON(paged$requests[[2L]]$body, simplifyVector = FALSE)
  expect_equal(second$offset, 1)
  second$offset <- NULL
  expect_identical(second, first)
  # The retained post hook expects an envelope, while paging returns collected records.
  expect_identical(paged$value, tibble::tibble())
  partial <- invoke(list(page(0), list(status = 500L, body = '{"error":"sentinel"}')), TRUE)
  expect_length(partial$requests, 2L)
  expect_identical(partial$stages, c('pre_request', 'post_response'))
  expect_identical(partial$value, tibble::tibble())
  for (status in c(404L, 500L)) {
    failed <- invoke(list(list(status = status, body = '{"error":"sentinel"}')))
    expect_length(failed$requests, 1L)
    expect_identical(failed$stages, 'pre_request')
    expect_s3_class(failed$value, paste0('httr2_http_', status))
    expect_identical(httr2::resp_body_string(failed$value$resp), '{"error":"sentinel"}')
  }
  malformed <- invoke(list(list(status = 200L, body = '{broken')))
  expect_length(malformed$requests, 1L)
  expect_identical(malformed$stages, 'pre_request')
  expect_s3_class(malformed$value, 'error')
  malformed_records <- invoke(list(list(status = 200L, body = '{"records":[{"a":[1,2],"b":[1,2,3]}]}')))
  expect_length(malformed_records$requests, 1L)
  expect_identical(malformed_records$stages, c('pre_request', 'post_response'))
  expect_s3_class(malformed_records$value, 'rlang_error')
  expect_s3_class(malformed_records$value$parent, 'purrr_error_indexed')
  expect_identical(malformed_records$value$parent$location, 1L)
  expect_s3_class(malformed_records$value$parent$parent, 'tibble_error_incompatible_size')
})
