test_that("received successful responses keep parsing and formatting errors hard", {
  local_mocked_bindings(req_perform = function(...) {
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('{broken'))
  }, .package = "httr2")
  withr::local_envvar(ctx_api_key = "local-response-error-key")
  for (fn in list(chemi_classyfire, ct_chemical_detail_search_by_dtxcid)) {
    expect_error(fn(c("one", "two")), class = "specmill_call_error")
  }
  # The reviewed AMOS collector parses after combination and keeps purrr's index.
  error <- tryCatch(chemi_amos_get_info_by_id(c("one", "two")), error = identity)
  expect_s3_class(error, "purrr_error_indexed")
  expect_identical(error$location, 1L)
  expect_s3_class(error$parent, "simpleError")
  expect_error(ComptoxR:::.ct_tidy(NULL, list(status = 200L),
    function() stop("decode sentinel")), "decode sentinel", class = "specmill_call_error")
  local_mocked_bindings(safe_tidy_bind = function(...) stop("formatter sentinel"))
  expect_error(ComptoxR:::.ct_tidy(NULL, list(status = 200L, query = NULL),
    function() list(value = 1)), "formatter sentinel", class = "specmill_call_error")
})

test_that("response classification preserves ordinary HTTP failure handling", {
  ordinary <- simpleError("HTTP failure")
  actual <- tryCatch(ComptoxR:::.ct_tidy(NULL, list(status = 500L),
    function() stop(ordinary)), error = identity)
  expect_identical(actual, ordinary)
  expect_false(inherits(actual, "specmill_call_error"))
})
