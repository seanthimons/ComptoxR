# Pipeline test infrastructure
# Provides utilities for sourcing dev/endpoint_eval/ pipeline files
# and managing .StubGenEnv state during tests

#' Source all pipeline files in dependency order
#'
#' Sources the 8 pipeline files from dev/endpoint_eval/ in the correct
#' dependency order so that functions are available for testing.
#'
#' @return Invisible TRUE on success
#' @export
source_pipeline_files <- function() {
  tryCatch({
    # Get package root directory
    pkg_root <- here::here()

    # Define pipeline files in dependency order
    pipeline_files <- c(
      "dev/endpoint_eval/00_config.R",           # No dependencies
      "dev/endpoint_eval/01_schema_resolution.R", # Depends on 00
      "dev/endpoint_eval/02_path_utils.R",        # Depends on 00
      "dev/endpoint_eval/03_codebase_search.R",   # Depends on 00, 02
      "dev/endpoint_eval/04_openapi_parser.R",    # Depends on 00, 01
      "dev/endpoint_eval/05_file_scaffold.R",     # Depends on 00
      "dev/endpoint_eval/06_param_parsing.R",     # Depends on 00, 01, 04
      "dev/endpoint_eval/07_stub_generation.R"    # Depends on all above
    )

    # Source each file
    for (file in pipeline_files) {
      file_path <- file.path(pkg_root, file)
      if (!file.exists(file_path)) {
        stop("Pipeline file not found: ", file_path)
      }
      source(file_path, local = FALSE)
    }

    invisible(TRUE)
  }, error = function(e) {
    stop("Failed to source pipeline files: ", conditionMessage(e), call. = FALSE)
  })
}

#' Clear stub generation environment state
#'
#' Removes all objects from .StubGenEnv or removes the environment entirely
#' to ensure clean test state. Designed for use with withr::defer() pattern.
#'
#' @return Invisible TRUE
#' @export
clear_stubgen_env <- function() {
  if (exists(".StubGenEnv", envir = .GlobalEnv)) {
    # Remove all objects from the environment
    rm(list = ls(.StubGenEnv), envir = .StubGenEnv)
  }
  invisible(TRUE)
}

#' Get path to test fixture file
#'
#' Constructs path to a fixture file in tests/testthat/fixtures/schemas/
#'
#' @param filename Name of the fixture file
#' @return Character path to fixture file
#' @export
get_fixture_path <- function(filename) {
  testthat::test_path("fixtures", "schemas", filename)
}

#' Load test fixture schema
#'
#' Loads and parses a JSON fixture schema from fixtures/schemas/
#'
#' @param filename Name of the fixture file (e.g., "minimal-openapi-3.json")
#' @return Parsed list from JSON
#' @export
load_fixture_schema <- function(filename) {
  path <- get_fixture_path(filename)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}
