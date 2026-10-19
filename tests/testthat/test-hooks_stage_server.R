test_that('public wrappers retain the configured host without fallback hooks', {
  withr::local_options(ComptoxR.chemi_burl = NULL)
  withr::local_envvar(chemi_burl = NA_character_)
  seen <- character()
  local_mocked_bindings(req_perform = function(req, ...) {
    seen <<- req$url
    httr2::response(status_code = 200, headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"ok":true}]'))
  }, .package = "httr2")
  expect_identical(chemi_alerts_metadata(), list(list(ok = TRUE)))
  expect_identical(seen, 'https://hcd.rtpnc.epa.gov/api/alerts/metadata')
  options(ComptoxR.chemi_burl = 'https://configured.example/api')
  expect_identical(chemi_alerts_metadata(), list(list(ok = TRUE)))
  expect_identical(seen, 'https://configured.example/api/alerts/metadata')
  expect_false(exists('enforce_stage_server', envir = asNamespace('ComptoxR'), inherits = FALSE))
})

test_that('manual hook ordering remains independent of empty generated policy', {
  merged <- merge_hook_configs(
    list(example = list(pre_request = c('first_hook', 'second_hook'))),
    list(example = list(pre_request = 'third_hook'))
  )
  expect_identical(merged$example$pre_request, c('first_hook', 'second_hook', 'third_hook'))
  generated <- system.file('hook_config_generated.yml', package = 'ComptoxR')
  expect_length(yaml::read_yaml(generated), 0L)
})
