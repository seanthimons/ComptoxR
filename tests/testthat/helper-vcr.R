# Helper functions for managing vcr cassettes

#' Delete all vcr cassettes to force re-recording from production
#'
#' @param confirm Logical. If FALSE, will prompt for confirmation.
#' @return NULL invisibly
#' @examples
#' \dontrun{
#' # Delete all cassettes and re-record from production
#' delete_all_cassettes()
#' devtools::test()
#' }
delete_all_cassettes <- function(confirm = FALSE) {
  cassette_dir <- "tests/testthat/fixtures"
  cassettes <- list.files(cassette_dir, pattern = "\\.yml$", full.names = TRUE)

  if (length(cassettes) == 0) {
    message("No cassettes found to delete.")
    return(invisible(NULL))
  }

  if (!confirm) {
    response <- readline(
      prompt = sprintf(
        "This will delete %d cassette(s). Tests will hit production API on next run. Continue? (yes/no): ",
        length(cassettes)
      )
    )
    if (tolower(response) != "yes") {
      message("Cancelled.")
      return(invisible(NULL))
    }
  }

  unlink(cassettes)
  message(sprintf("Deleted %d cassette(s). Next test run will record from production.", length(cassettes)))
  invisible(NULL)
}

#' Delete specific vcr cassette(s)
#'
#' @param pattern Character. Pattern to match cassette names (e.g., "ct_env_fate")
#' @param confirm Logical. If FALSE, will prompt for confirmation.
#' @return NULL invisibly
#' @examples
#' \dontrun{
#' # Delete only ct_env_fate cassettes
#' delete_cassettes("ct_env_fate")
#' }
delete_cassettes <- function(pattern, confirm = FALSE) {
  cassette_dir <- "tests/testthat/fixtures"
  all_cassettes <- list.files(cassette_dir, pattern = "\\.yml$", full.names = TRUE)
  matching <- grep(pattern, all_cassettes, value = TRUE)

  if (length(matching) == 0) {
    message(sprintf("No cassettes matching '%s' found.", pattern))
    return(invisible(NULL))
  }

  message("Cassettes to delete:")
  cat(paste0("  - ", basename(matching), collapse = "\n"), "\n")

  if (!confirm) {
    response <- readline(
      prompt = sprintf("Delete %d cassette(s)? (yes/no): ", length(matching))
    )
    if (tolower(response) != "yes") {
      message("Cancelled.")
      return(invisible(NULL))
    }
  }

  unlink(matching)
  message(sprintf("Deleted %d cassette(s).", length(matching)))
  invisible(NULL)
}

#' List all vcr cassettes
#'
#' @return Character vector of cassette file names
list_cassettes <- function() {
  cassette_dir <- "tests/testthat/fixtures"
  cassettes <- list.files(cassette_dir, pattern = "\\.yml$")

  if (length(cassettes) == 0) {
    message("No cassettes found.")
    return(invisible(character(0)))
  }

  message(sprintf("Found %d cassette(s):", length(cassettes)))
  cat(paste0("  - ", cassettes, collapse = "\n"), "\n")
  invisible(cassettes)
}

#' Check cassette for sensitive data
#'
#' @param cassette_name Character. Name of cassette file (with or without .yml)
#' @return Logical. TRUE if potential sensitive data found (requires manual review)
check_cassette_safety <- function(cassette_name) {
  if (!grepl("\\.yml$", cassette_name)) {
    cassette_name <- paste0(cassette_name, ".yml")
  }

  cassette_path <- file.path("tests/testthat/fixtures", cassette_name)

  if (!file.exists(cassette_path)) {
    stop(sprintf("Cassette not found: %s", cassette_path))
  }

  content <- readLines(cassette_path, warn = FALSE)

  # Check for potentially sensitive patterns
  has_api_key_placeholder <- any(grepl("<<<API_KEY>>>", content, fixed = TRUE))
  has_raw_key_pattern <- any(grepl("[0-9a-f]{32,}", content))
  has_email <- any(grepl("@.*\\.com", content))

  message(sprintf("\nSafety check for: %s", cassette_name))
  message(sprintf("  API key filtered: %s", ifelse(has_api_key_placeholder, "YES", "NO (WARNING)")))
  message(sprintf("  Potential raw keys: %s", ifelse(has_raw_key_pattern, "YES (review needed)", "NO")))
  message(sprintf("  Email addresses: %s", ifelse(has_email, "YES (review needed)", "NO")))

  if (!has_api_key_placeholder || has_raw_key_pattern) {
    warning("Manual review recommended before committing this cassette!")
    return(FALSE)
  }

  message("  Cassette appears safe to commit.")
  return(TRUE)
}
