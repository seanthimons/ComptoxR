test_that('session credentials validate input without reading or writing files', {
  withr::local_envvar(c(ctx_api_key = NA_character_))
  expect_error(api_token(), class = 'specmill_call_error')
  expect_error(api_token('unknown'), class = 'specmill_call_error')
  expect_error(set_api_token('line\nbreak'), 'without line breaks')
  expect_identical(Sys.getenv('ctx_api_key', unset = ''), '')

  result <- withVisible(set_api_token('test-session-token', file = stop('file forced')))
  expect_null(result$value)
  expect_false(result$visible)
  expect_identical(api_token(), 'test-session-token')
  expect_identical(api_token('ctx'), 'test-session-token')

  Sys.setenv(ctx_api_key = 'line\rbreak')
  expect_error(api_token(), 'line break', class = 'specmill_call_error')
})

test_that('persisting credentials preserves unrelated settings in a temporary file', {
  withr::local_envvar(c(ctx_api_key = NA_character_))
  file <- tempfile('credential-test-')
  withr::defer(unlink(file))
  original <- c('# unrelated setting', 'OTHER_SETTING=value', 'ctx_api_key="old-test-token"')
  writeLines(original, file)
  expect_error(set_api_token('unsafe${expansion}', persist = TRUE, file = file), 'safely saved')
  expect_identical(readLines(file), original)
  expect_identical(Sys.getenv('ctx_api_key', unset = ''), '')

  message <- capture.output(set_api_token('new-test-token', persist = TRUE, file = file), type = 'message')
  expect_false(any(grepl('new-test-token', message, fixed = TRUE)))
  expect_identical(readLines(file), c(original[1:2], 'ctx_api_key="new-test-token"'))
  expect_identical(api_token(), 'new-test-token')
})
