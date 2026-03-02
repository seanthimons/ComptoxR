library(vcr)

# Configure vcr
vcr_dir <- "../testthat/fixtures"
if (!dir.exists(vcr_dir)) dir.create(vcr_dir, recursive = TRUE)

vcr::vcr_configure(
  dir = vcr_dir,
  filter_sensitive_data = list(
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
  )
)

# Cassette Management Helpers ------------------------------------------------

#' List all VCR cassette files
#'
#' @return Character vector of cassette filenames (no paths)
#' @export
list_cassettes <- function() {
  cassette_dir <- here::here("tests/testthat/fixtures")
  if (!dir.exists(cassette_dir)) {
    return(character(0))
  }
  cassettes <- fs::dir_ls(cassette_dir, glob = "*.yml")
  fs::path_file(cassettes)
}

#' Delete all VCR cassette files
#'
#' @param dry_run Logical. If TRUE (default), show what would be deleted without actually deleting.
#' @return Invisible character vector of cassette file paths
#' @export
delete_all_cassettes <- function(dry_run = TRUE) {
  cassette_dir <- here::here("tests/testthat/fixtures")
  if (!dir.exists(cassette_dir)) {
    cli::cli_alert_info("No cassette directory found")
    return(invisible(character(0)))
  }

  cassettes <- fs::dir_ls(cassette_dir, glob = "*.yml")

  if (length(cassettes) == 0) {
    cli::cli_alert_info("No cassettes found")
    return(invisible(character(0)))
  }

  if (dry_run) {
    cli::cli_alert_info("Would delete {length(cassettes)} cassette{?s}")
    cli::cli_alert_warning("Set dry_run = FALSE to actually delete")
  } else {
    fs::file_delete(cassettes)
    cli::cli_alert_success("Deleted {length(cassettes)} cassette{?s}")
  }

  invisible(cassettes)
}

#' Delete VCR cassettes matching a pattern
#'
#' @param pattern Character string. If contains '*', treated as glob; otherwise treated as regex.
#' @param dry_run Logical. If TRUE (default), show what would be deleted without actually deleting.
#' @return Invisible character vector of matched cassette file paths
#' @export
delete_cassettes <- function(pattern, dry_run = TRUE) {
  cassette_dir <- here::here("tests/testthat/fixtures")
  if (!dir.exists(cassette_dir)) {
    cli::cli_alert_info("No cassette directory found")
    return(invisible(character(0)))
  }

  # Determine if pattern is glob or regex
  if (grepl("\\*", pattern)) {
    cassettes <- fs::dir_ls(cassette_dir, glob = pattern)
  } else {
    cassettes <- fs::dir_ls(cassette_dir, regexp = pattern)
  }

  if (length(cassettes) == 0) {
    cli::cli_alert_warning("No cassettes match pattern: {pattern}")
    return(invisible(character(0)))
  }

  if (dry_run) {
    cli::cli_alert_info("Would delete {length(cassettes)} cassette{?s} matching '{pattern}':")
    cli::cli_bullets(setNames(fs::path_file(cassettes), rep("*", length(cassettes))))
    cli::cli_alert_warning("Set dry_run = FALSE to actually delete")
  } else {
    fs::file_delete(cassettes)
    cli::cli_alert_success("Deleted {length(cassettes)} cassette{?s} matching '{pattern}'")
  }

  invisible(cassettes)
}

#' Check VCR cassettes for leaked API keys and auth headers
#'
#' @param pattern Optional regex pattern to filter cassettes. If NULL, checks all cassettes.
#' @return Invisible named list of issues found (empty if all cassettes are clean)
#' @export
check_cassette_safety <- function(pattern = NULL) {
  cassette_dir <- here::here("tests/testthat/fixtures")
  if (!dir.exists(cassette_dir)) {
    cli::cli_alert_info("No cassette directory found")
    return(invisible(list()))
  }

  # Get all cassettes
  if (is.null(pattern)) {
    cassettes <- fs::dir_ls(cassette_dir, glob = "*.yml")
  } else {
    cassettes <- fs::dir_ls(cassette_dir, regexp = pattern)
  }

  if (length(cassettes) == 0) {
    cli::cli_alert_info("No cassettes to check")
    return(invisible(list()))
  }

  issues <- list()
  api_key <- Sys.getenv("ctx_api_key")

  for (cassette in cassettes) {
    cassette_name <- fs::path_file(cassette)
    lines <- readLines(cassette, warn = FALSE)

    # Check for unfiltered x-api-key headers
    api_key_lines <- grep("x-api-key:", lines, ignore.case = TRUE, value = TRUE)
    if (length(api_key_lines) > 0) {
      # Check if any contain actual keys (not the placeholder)
      unfiltered <- api_key_lines[!grepl("<<<API_KEY>>>", api_key_lines, fixed = TRUE)]
      if (length(unfiltered) > 0) {
        issues[[cassette_name]] <- "Unfiltered x-api-key header found"
      }
    }

    # Check for Authorization headers with Bearer tokens
    auth_lines <- grep("Authorization:", lines, ignore.case = TRUE, value = TRUE)
    if (length(auth_lines) > 0) {
      bearer_lines <- grep("Bearer", auth_lines, value = TRUE)
      if (length(bearer_lines) > 0) {
        issues[[cassette_name]] <- "Authorization Bearer token found"
      }
    }

    # Check for actual API key value in content
    if (nzchar(api_key)) {
      if (any(grepl(api_key, lines, fixed = TRUE))) {
        issues[[cassette_name]] <- "Actual API key value found in cassette"
      }
    }
  }

  # Report results
  if (length(issues) == 0) {
    cli::cli_alert_success("All {length(cassettes)} cassette{?s} are clean")
  } else {
    cli::cli_alert_danger("Found issues in {length(issues)} cassette{?s}:")
    purrr::iwalk(issues, function(issue, name) {
      cli::cli_alert_danger("{name}: {issue}")
    })
  }

  invisible(issues)
}

#' Find cassettes with HTTP error responses (4xx/5xx)
#'
#' Scans cassette files for non-2xx status codes. These "poison" cassettes
#' will replay error responses forever and should be deleted and re-recorded.
#'
#' @param delete Logical. If TRUE, delete bad cassettes. Default FALSE (report only).
#' @return Invisible data frame with columns: cassette, status
#' @export
check_cassette_errors <- function(delete = FALSE) {
  cassette_dir <- here::here("tests/testthat/fixtures")
  if (!dir.exists(cassette_dir)) {
    cli::cli_alert_info("No cassette directory found")
    return(invisible(data.frame(cassette = character(), status = integer())))
  }

  cassettes <- fs::dir_ls(cassette_dir, glob = "*.yml")
  if (length(cassettes) == 0) {
    cli::cli_alert_info("No cassettes found")
    return(invisible(data.frame(cassette = character(), status = integer())))
  }

  bad <- data.frame(cassette = character(), status = integer(), stringsAsFactors = FALSE)

  for (cassette in cassettes) {
    lines <- readLines(cassette, warn = FALSE)
    status_lines <- grep("^\\s+status:\\s+[0-9]+", lines, value = TRUE)
    codes <- as.integer(gsub("\\D", "", status_lines))
    error_codes <- codes[codes >= 400]
    if (length(error_codes) > 0) {
      bad <- rbind(bad, data.frame(
        cassette = fs::path_file(cassette),
        status = error_codes[1],
        stringsAsFactors = FALSE
      ))
    }
  }

  if (nrow(bad) == 0) {
    cli::cli_alert_success("All {length(cassettes)} cassettes have clean responses")
  } else {
    cli::cli_alert_danger("Found {nrow(bad)} cassette{?s} with error responses:")
    for (i in seq_len(nrow(bad))) {
      cli::cli_alert_warning("{bad$cassette[i]} (HTTP {bad$status[i]})")
    }
    if (delete) {
      paths <- fs::path(cassette_dir, bad$cassette)
      fs::file_delete(paths)
      cli::cli_alert_success("Deleted {nrow(bad)} bad cassette{?s}")
    } else {
      cli::cli_alert_info("Run check_cassette_errors(delete = TRUE) to remove them")
    }
  }

  invisible(bad)
}
