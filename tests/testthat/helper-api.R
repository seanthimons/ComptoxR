#' Skip test if no internet connection
skip_if_offline <- function() {
  # We use a simple check for internet
  # httr2 doesn't have a direct skip_if_offline, but we can check if we can resolve a host
  if (!curl::has_internet()) {
    testthat::skip("No internet connection")
  }
}

#' Skip test if no real API key is available
skip_if_no_key <- function() {
  key <- Sys.getenv("ctx_api_key")
  if (key == "" || key == "dummy_ctx_key") {
    testthat::skip("No real API key available")
  }
}

#' Standard expectations for ComptoxR tibbles
expect_valid_tibble <- function(object) {
  expect_s3_class(object, "tbl_df")
  expect_true(nrow(object) >= 0)
}
