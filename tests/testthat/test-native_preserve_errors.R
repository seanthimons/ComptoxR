test_that('the released decoder preserves typed received HTTP errors only when selected', {
  for (status in c(200L, 404L, 500L, 401L)) for (preserve in c(FALSE, TRUE)) {
    response <- httr2::response(status_code = status,
      headers = list(`Content-Type` = 'application/json'), body = charToRaw('{"value":1}'))
    value <- tryCatch(.ct_request_decode(response, preserve_errors = preserve), error = identity)
    if (status == 200L) {
      expect_identical(value, list(value = 1L))
    } else if (status == 401L) {
      expect_s3_class(value, 'specmill_call_error')
    } else if (preserve) {
      expect_s3_class(value, paste0('httr2_http_', status))
      expect_identical(value$resp, response)
    } else {
      expect_s3_class(value, 'simpleError')
      expect_false(inherits(value, 'httr2_error'))
    }
  }
  response <- httr2::response(status_code = 200L,
    headers = list(`Content-Type` = 'text/plain'), body = charToRaw('standalone'))
  expect_identical(.ct_request_decode(response, policy_query = 'one',
    response_policy = function(response, context, decode) list(value = decode(), query = context$query)),
    list(value = 'standalone', query = 'one'))
  expect_error(.ct_request_decode(response, preserve_errors = NA), class = 'specmill_call_error')
})

test_that('native error preservation retains the original transport condition', {
  original <- structure(list(message = 'transport failed', call = NULL, resp = NULL),
    class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition'))
  local_mocked_bindings(req_perform = function(...) stop(original), .package = 'httr2')
  invoke <- function(controls) tryCatch(.ct_request(method = 'GET', path = '/test', path_params = list(), query = list(), body = NULL,
    server = list(url = 'https://example.invalid'), request_controls = controls), error = identity)
  expect_identical(invoke(list(preserve_errors = TRUE)), original)
  expect_false(inherits(invoke(list()), 'httr2_error'))
  expect_s3_class(invoke(list(preserve_errors = NA)), 'specmill_call_error')
})
