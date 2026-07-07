#' Detect the CRAN-safe test lane
comptoxr_cran_safe_tests <- function() {
  cran_safe <- tolower(trimws(Sys.getenv("COMPTOXR_CRAN_SAFE_TESTS", unset = "")))
  if (cran_safe %in% c("true", "1", "yes")) {
    return(TRUE)
  }

  not_cran <- tolower(trimws(Sys.getenv("NOT_CRAN", unset = "")))
  !identical(not_cran, "true")
}

#' Detect whether a ctx_api_key value is suitable for live API calls
has_real_ctx_api_key <- function(value = Sys.getenv("ctx_api_key", unset = "")) {
  value <- trimws(value)
  lower <- tolower(value)

  placeholder_patterns <- c(
    "^$",
    "dummy",
    "placeholder",
    "your[_ -]?key",
    "token here",
    "api[_ -]?key",
    "redacted",
    "masked",
    "^x+$",
    "^\\*+$",
    "^<+.*>+$",
    "<<<.*>>>",
    "^test$",
    "^test[_ -]",
    "[_ -]test[_ -]",
    "logic_test_key"
  )

  !any(vapply(placeholder_patterns, grepl, logical(1), x = lower, perl = TRUE))
}

#' Skip test if no internet connection
skip_if_offline <- function() {
  if (comptoxr_cran_safe_tests()) {
    testthat::skip("External connectivity disabled in CRAN-safe test mode")
  }

  # We use a simple check for internet
  # httr2 doesn't have a direct skip_if_offline, but we can check if we can resolve a host
  if (!curl::has_internet()) {
    testthat::skip("No internet connection")
  }
}

#' Skip test if no real API key is available
skip_if_no_key <- function() {
  if (!has_real_ctx_api_key()) {
    testthat::skip("No real API key available")
  }
}

#' Skip tests that require external services in the CRAN-safe lane
skip_if_cran_safe_external <- function(
  reason = "Test requires secrets, network, local services, or live APIs"
) {
  if (comptoxr_cran_safe_tests()) {
    testthat::skip(reason)
  }
}

#' Skip a test when the local DuckDB for `db` is not installed
#'
#' DB-backed tests ship no database fixture; they skip when the file is absent.
#' In the CRAN-safe / offline lane, setup.R points the `*_path()` options at a
#' missing directory, so these skip automatically. Equivalent to the inline
#' `skip_if_not(file.exists(eco_path()), ...)` idiom; prefer this in new tests.
skip_if_no_local_db <- function(db = c("ecotox", "toxval")) {
  db <- match.arg(db)
  path <- switch(db, ecotox = eco_path(), toxval = toxval_path())
  if (!file.exists(path)) {
    testthat::skip(sprintf("%s database not installed", db))
  }
}

#' Standard expectations for ComptoxR tibbles
expect_valid_tibble <- function(object) {
  expect_s3_class(object, "tbl_df")
  expect_true(nrow(object) >= 0)
}
