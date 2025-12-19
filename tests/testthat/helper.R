# Helper functions for tests
# This file is loaded before tests are run

#' Skip test if API key is not available
#'
#' @return NULL invisibly, or skips test
skip_if_no_api_key <- function() {
  if (Sys.getenv("ctx_api_key") == "" ||
    Sys.getenv("ctx_api_key") == "test_api_key_placeholder") {
    skip("API key not available")
  }
}

#' Skip test if base URL is not set
#'
#' @return NULL invisibly, or skips test
skip_if_no_base_url <- function() {
  if (Sys.getenv("ctx_burl") == "") {
    skip("Base URL not set")
  }
}

#' Check if running in CI environment
#'
#' @return logical
is_ci <- function() {
  isTRUE(as.logical(Sys.getenv("CI", "false")))
}

#' Skip if not in CI
skip_if_not_ci <- function() {
  if (!is_ci()) {
    skip("Not running in CI environment")
  }
}

#' Create test DTXSIDs
#'
#' @return character vector of test DTXSIDs
get_test_dtxsids <- function() {
  c(
		'DTXSID1024122', # Glyphosate
		'DTXSID4020533', # 1,4-Dioxane
		'DTXSID7020182', # Bisphenol A
		'DTXSID7024902' # Dazomet
  )
}
