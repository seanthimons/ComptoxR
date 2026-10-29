safety_sids <- c('DTXSID0020153', 'DTXSID0020600', 'DTXSID0022018')
safety_records <- lapply(safety_sids, function(sid) {
  list(result = 'FOUND', chemical = list(chemId = sid, sid = sid, smiles = 'C'))
})
safety_response <- list(
  list(rqCode = list(sid = safety_sids[[1]], name = 'Benzyl chloride', category = 'B', rq = '100 (45.4)')),
  list(chemical = list(sid = safety_sids[[2]])),
  list(rqCode = list(sid = safety_sids[[3]], name = 'Disulfoton', category = 'X', rq = '1 (0.454)'))
)

mock_safety_http <- function(resolver = safety_records, safety = safety_response,
                             status = 200L, malformed = FALSE) {
  capture <- new.env(parent = emptyenv())
  capture$requests <- list()
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    capture$requests[[length(capture$requests) + 1L]] <- req
    lookup <- endsWith(req$url, '/resolver/lookup')
    body <- if (lookup) resolver else safety
    httr2::response(status_code = if (lookup) 200L else status,
      headers = list(`Content-Type` = 'application/json'),
      body = charToRaw(if (!lookup && malformed) '{broken' else
        jsonlite::toJSON(body, auto_unbox = TRUE, null = 'null')))
  }, .package = 'httr2', .env = parent.frame())
  capture
}

test_that('SID queries resolve once and send a flat Chemical array with RQ formatting', {
  capture <- mock_safety_http()
  result <- chemi_safety_rqcodes(safety_sids)
  expect_length(capture$requests, 2L)
  lookup <- capture$requests[[1L]]
  safety <- capture$requests[[2L]]
  expect_match(lookup$url, '/api/resolver/lookup$', fixed = FALSE)
  expect_identical(lookup$body$data$ids, as.list(safety_sids))
  expect_identical(lookup$body$data$idsType, 'DTXSID')
  expect_match(safety$url, '/api/safety/rqcodes$')
  expect_identical(safety$method, 'POST')
  expect_identical(vapply(safety$body$data, `[[`, '', 'sid'), safety_sids)
  expect_null(names(safety$body$data))
  expect_null(safety$body$data[[1L]]$chemical)
  expect_identical(safety$body$data[[1L]]$smiles, 'C')
  expect_equal(result$rq_lbs, c(100, 1))
  expect_equal(result$rq_kgs, c(45.4, 0.454))
  expect_identical(result$sid, safety_sids[c(1, 3)])
})

test_that('invalid SID inputs are rejected before any HTTP', {
  capture <- mock_safety_http()
  expect_error(chemi_safety_rqcodes(), 'Either query or chemicals parameter must be provided', class = 'rlang_error')
  for (query in list(NULL, character(), '', NA_character_, 1, list(safety_sids[[1]]), '50-00-0', 'DTXSID', c(safety_sids[[1]], NA))) {
    expect_error(chemi_safety_rqcodes(query), class = 'rlang_error')
  }
  expect_length(capture$requests, 0L)
})

test_that('unresolved SIDs skip safety and missing RQ codes return NULL', {
  capture <- mock_safety_http(resolver = list(list(result = 'NOT_FOUND')))
  expect_warning(expect_null(chemi_safety_rqcodes(safety_sids)), 'No chemicals could be resolved')
  expect_length(capture$requests, 1L)
  capture <- mock_safety_http(safety = list(list(chemical = list(sid = safety_sids[[1]]))))
  expect_null(chemi_safety_rqcodes(safety_sids[[1]]))
  capture <- mock_safety_http(safety = list())
  expect_null(chemi_safety_rqcodes(safety_sids[[1]]))
})

test_that('safety preserves formatting warnings, errors and typed HTTP failures', {
  capture <- mock_safety_http(safety = list(list(rqCode = list(rq = 'bad units extra'))))
  expect_error(chemi_safety_rqcodes(safety_sids), class = 'rlang_error')
  capture <- mock_safety_http(safety = list(list(rqCode = list(rq = 'bad (bad)'))))
  expect_warning(value <- chemi_safety_rqcodes(safety_sids), 'NAs introduced by coercion')
  expect_true(all(is.na(value$rq_lbs)))
  capture <- mock_safety_http(malformed = TRUE)
  expect_error(chemi_safety_rqcodes(safety_sids))
  withr::local_options(list(comptoxr_native.request = list(max_retries = 0L)))
  for (status in c(400L, 500L)) {
    capture <- mock_safety_http(status = status)
    expect_error(chemi_safety_rqcodes(safety_sids), class = paste0('httr2_http_', status))
  }
  capture <- mock_safety_http(status = 401L)
  expect_error(chemi_safety_rqcodes(safety_sids), class = 'specmill_call_error')
})

test_that('RQ formatting retains thousands, zero and additional fields', {
  capture <- mock_safety_http(safety = list(
    list(rqCode = list(code = 'A', rq = '1,000 (454)', flag = FALSE, count = 0)),
    list(rqCode = NULL),
    list(rqCode = list(code = 'B', rq = '0 (0)', flag = FALSE, count = 0))))
  expect_identical(chemi_safety_rqcodes(safety_sids), tibble::tibble(
    code = c('A', 'B'), rq_lbs = c(1000, 0), rq_kgs = c(454, 0),
    flag = c(FALSE, FALSE), count = c(0L, 0L)))
})

test_that('duplicate SIDs resolve once and transport failures propagate', {
  capture <- mock_safety_http()
  chemi_safety_rqcodes(rep(safety_sids[[1]], 2))
  expect_identical(capture$requests[[1L]]$body$data$ids, as.list(safety_sids[[1]]))
  local_mocked_bindings(chemi_resolver_lookup_bulk = function(...) safety_records)
  local_mocked_bindings(req_perform = function(...) stop('transport sentinel'), .package = 'httr2')
  expect_error(chemi_safety_rqcodes(safety_sids), 'transport sentinel')
})
