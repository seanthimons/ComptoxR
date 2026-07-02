capture_skip <- function(expr) {
  tryCatch(
    {
      force(expr)
      NULL
    },
    skip = function(condition) condition
  )
}

test_that("CRAN-safe predicate follows explicit opt-in and NOT_CRAN", {
  withr::local_envvar(c(COMPTOXR_CRAN_SAFE_TESTS = "true", NOT_CRAN = "true"))
  expect_true(comptoxr_cran_safe_tests())

  withr::local_envvar(c(COMPTOXR_CRAN_SAFE_TESTS = NA, NOT_CRAN = "true"))
  expect_false(comptoxr_cran_safe_tests())

  withr::local_envvar(c(COMPTOXR_CRAN_SAFE_TESTS = NA, NOT_CRAN = "false"))
  expect_true(comptoxr_cran_safe_tests())

  withr::local_envvar(c(COMPTOXR_CRAN_SAFE_TESTS = NA, NOT_CRAN = NA))
  expect_true(comptoxr_cran_safe_tests())
})

test_that("real API key predicate rejects placeholders and redacted values", {
  invalid_values <- c(
    "",
    "dummy_ctx_key",
    "placeholder-token",
    "your_key_here",
    "test_api_key",
    "logic_test_key",
    "redacted",
    "masked",
    "xxxxxxxx",
    "********",
    "<<<API_KEY>>>"
  )

  expect_false(any(vapply(invalid_values, has_real_ctx_api_key, logical(1))))
  expect_true(has_real_ctx_api_key("realistic-token-value-123"))
})

test_that("skip helpers use CRAN-safe and real-key predicates", {
  withr::local_envvar(c(COMPTOXR_CRAN_SAFE_TESTS = "true", NOT_CRAN = "true"))
  offline_skip <- capture_skip(skip_if_offline())
  expect_s3_class(offline_skip, "skip")
  expect_match(conditionMessage(offline_skip), "CRAN-safe")

  external_skip <- capture_skip(skip_if_cran_safe_external())
  expect_s3_class(external_skip, "skip")
  expect_match(conditionMessage(external_skip), "secrets")

  withr::local_envvar(c(ctx_api_key = "dummy_ctx_key"))
  key_skip <- capture_skip(skip_if_no_key())
  expect_s3_class(key_skip, "skip")
  expect_match(conditionMessage(key_skip), "No real API key")
})

test_that("vcr record mode is playback-only in CRAN-safe mode", {
  withr::local_envvar(c(COMPTOXR_CRAN_SAFE_TESTS = "true", NOT_CRAN = "true"))
  expect_equal(comptoxr_vcr_record_mode(), "none")
  expect_equal(comptoxr_vcr_config(tempdir())$record, "none")

  withr::local_envvar(c(COMPTOXR_CRAN_SAFE_TESTS = NA, NOT_CRAN = "true"))
  expect_null(comptoxr_vcr_record_mode())
  expect_false("record" %in% names(comptoxr_vcr_config(tempdir())))
})
