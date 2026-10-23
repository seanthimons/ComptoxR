# chemi_toxprints_bulk live behavior is verified by dev/specmill-rebuild/issue-353/live.R.
test_that('ToxPrint bulk replacement preserves its GET sibling', {
  root <- test_path('../..')
  path <- file.path(root, 'dev/specmill-rebuild/issue-353/before.json')
  skip_if_not(file.exists(path))
  before <- jsonlite::read_json(path)
  old <- eval(parse(text = before$GET_prefix, keep.source = FALSE)[[1L]][[3L]], baseenv())
  current <- eval(parse(file.path(root, 'R/chemi_toxprints.R'), keep.source = FALSE)[[1L]][[3L]], baseenv())
  expect_identical(formals(current), formals(old))
  expect_identical(body(current), body(old))
  expect_identical(names(formals(chemi_toxprints_bulk)), 'query')
})

test_that('ToxPrint bulk builds cleaned canonical chunks without CTX authentication', {
  withr::local_options(comptoxr_native.dry_run = TRUE,
    ComptoxR.chemi_burl = "https://hcd.rtpnc.epa.gov")
  withr::local_envvar(c(batch_limit = '2', ctx_api_key = 'unused-test-key'))
  requests <- chemi_toxprints_bulk(c('CCO', 'CCCO', 'CCCCO', 'CCO', NA, ''))
  expect_length(requests, 2L)
  expect_identical(requests[[1L]]$body$data, list(chemicals = list('CCO', 'CCCO')))
  expect_identical(requests[[2L]]$body$data, list(chemicals = list('CCCCO')))
  for (request in requests) {
    expect_s3_class(request, 'httr2_request')
    expect_identical(request$method, 'POST')
    expect_identical(request$url, 'https://hcd.rtpnc.epa.gov/api/toxprints')
    expect_false('x-api-key' %in% tolower(names(request$headers)))
  }
  expect_error(chemi_toxprints_bulk(c('', NA_character_)), 'Query must')
  expect_error(chemi_toxprints_bulk(12))
  withr::local_envvar(batch_limit = '0')
  expect_error(chemi_toxprints_bulk('CCO'), 'batch_limit')
})

test_that('ToxPrint bulk preserves descriptor vectors from a real service response', {
  fixture <- jsonlite::read_json(test_path('fixtures/toxprints-canonical-response.json'))
  local_mocked_bindings(req_perform = function(...) {
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = 'application/json'),
      body = charToRaw(jsonlite::toJSON(fixture, auto_unbox = TRUE)))
  }, .package = 'httr2')
  result <- chemi_toxprints_bulk('CCO')
  expect_s3_class(result, 'tbl_df')
  expect_identical(result$smiles, 'CCO')
  expect_identical(result$descriptors[[1L]], unlist(fixture$chemicals[[1L]]$descriptors))
  expect_identical(result$info[[1L]], fixture$info)
})
