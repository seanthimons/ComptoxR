# ==============================================================================
# Schema Diffing Engine
# ==============================================================================
# Purpose: Compare two versions of OpenAPI schemas at the endpoint level
# Output: Structured diff report with breaking/non-breaking classification
# Usage: Called by CI workflow to detect API changes between schema versions

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(purrr)
  library(tibble)
  library(here)
})

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

#' Classify parameter changes as breaking or non-breaking
#'
#' @param old_params Comma-separated string of old parameter names
#' @param new_params Comma-separated string of new parameter names
#' @return List with breaking (logical) and detail (string)
classify_param_change <- function(old_params, new_params) {
  # Handle empty strings
  old_params <- if (is.na(old_params) || nchar(old_params) == 0) character(0) else strsplit(old_params, ",")[[1]]
  new_params <- if (is.na(new_params) || nchar(new_params) == 0) character(0) else strsplit(new_params, ",")[[1]]

  old_set <- trimws(old_params)
  new_set <- trimws(new_params)

  removed <- setdiff(old_set, new_set)
  added <- setdiff(new_set, old_set)

  if (length(removed) > 0) {
    # Removing params is breaking
    detail <- sprintf("params removed: [%s]", paste(removed, collapse = ", "))
    return(list(breaking = TRUE, detail = detail))
  } else if (length(added) > 0) {
    # Adding params is non-breaking
    detail <- sprintf("params added: [%s]", paste(added, collapse = ", "))
    return(list(breaking = FALSE, detail = detail))
  } else {
    # No change (shouldn't happen, but handle it)
    return(list(breaking = FALSE, detail = "params unchanged"))
  }
}

# ------------------------------------------------------------------------------
# Single Schema Diff
# ------------------------------------------------------------------------------

#' Compare two versions of a single schema file
#'
#' @param old_path Path to old schema JSON file
#' @param new_path Path to new schema JSON file
#' @return List with schema_file, added (tibble), removed (tibble), modified (tibble)
diff_single_schema <- function(old_path, new_path) {
  # Handle errors gracefully
  tryCatch({
    # Source the openapi parser and its dependencies if not already loaded
    if (!exists("openapi_to_spec")) {
      suppressMessages({
        source(here::here("dev/endpoint_eval/00_config.R"))
        source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
        source(here::here("dev/endpoint_eval/06_param_parsing.R"))
        source(here::here("dev/endpoint_eval/04_openapi_parser.R"))
      })
    }

    # Parse both schemas
    old_json <- jsonlite::fromJSON(old_path, simplifyVector = FALSE)
    new_json <- jsonlite::fromJSON(new_path, simplifyVector = FALSE)

    old_spec <- suppressMessages(openapi_to_spec(old_json))
    new_spec <- suppressMessages(openapi_to_spec(new_json))

    # Create endpoint keys as "{METHOD} {route}"
    old_spec <- old_spec %>%
      mutate(endpoint_key = paste(method, route))
    new_spec <- new_spec %>%
      mutate(endpoint_key = paste(method, route))

    old_keys <- old_spec$endpoint_key
    new_keys <- new_spec$endpoint_key

    # Detect changes
    added_keys <- setdiff(new_keys, old_keys)
    removed_keys <- setdiff(old_keys, new_keys)
    common_keys <- intersect(old_keys, new_keys)

    # Build added tibble
    added <- new_spec %>%
      filter(endpoint_key %in% added_keys) %>%
      select(route, method, summary) %>%
      arrange(route, method)

    # Build removed tibble
    removed <- old_spec %>%
      filter(endpoint_key %in% removed_keys) %>%
      select(route, method, summary) %>%
      arrange(route, method)

    # Build modified tibble
    modified_rows <- list()
    for (key in common_keys) {
      old_row <- old_spec %>% filter(endpoint_key == key)
      new_row <- new_spec %>% filter(endpoint_key == key)

      changes <- list()

      # Compare params
      if (!identical(old_row$params, new_row$params)) {
        param_change <- classify_param_change(old_row$params, new_row$params)
        changes <- c(changes, list(list(
          type = "params",
          breaking = param_change$breaking,
          detail = param_change$detail
        )))
      }

      # Compare body_params
      if (!identical(old_row$body_params, new_row$body_params)) {
        param_change <- classify_param_change(old_row$body_params, new_row$body_params)
        changes <- c(changes, list(list(
          type = "body_params",
          breaking = param_change$breaking,
          detail = sprintf("body %s", param_change$detail)
        )))
      }

      # Compare has_body
      if (!identical(old_row$has_body, new_row$has_body)) {
        if (new_row$has_body && !old_row$has_body) {
          changes <- c(changes, list(list(
            type = "body_added",
            breaking = TRUE,
            detail = "request body added"
          )))
        } else {
          changes <- c(changes, list(list(
            type = "body_removed",
            breaking = TRUE,
            detail = "request body removed"
          )))
        }
      }

      # Compare deprecated status
      if (!identical(old_row$deprecated, new_row$deprecated)) {
        if (new_row$deprecated && !old_row$deprecated) {
          changes <- c(changes, list(list(
            type = "deprecated",
            breaking = FALSE,
            detail = "endpoint deprecated"
          )))
        }
      }

      # If any changes detected, add to modified list
      if (length(changes) > 0) {
        for (change in changes) {
          modified_rows <- c(modified_rows, list(tibble(
            route = new_row$route,
            method = new_row$method,
            change_type = change$type,
            detail = change$detail,
            breaking = change$breaking
          )))
        }
      }
    }

    # Combine modified rows into a tibble
    modified <- if (length(modified_rows) > 0) {
      bind_rows(modified_rows) %>% arrange(route, method)
    } else {
      tibble(route = character(), method = character(), change_type = character(),
             detail = character(), breaking = logical())
    }

    list(
      schema_file = basename(new_path),
      added = added,
      removed = removed,
      modified = modified
    )

  }, error = function(e) {
    list(
      schema_file = basename(new_path),
      error = as.character(e$message)
    )
  })
}

# ------------------------------------------------------------------------------
# Multi-Schema Diff
# ------------------------------------------------------------------------------

#' Compare all schemas between two directories
#'
#' @param old_dir Directory containing old schema JSON files
#' @param new_dir Directory containing new schema JSON files
#' @param pattern File pattern to match (default: "\\.json$")
#' @return List of per-schema diff results
diff_schemas <- function(old_dir, new_dir, pattern = "\\.json$") {
  # List files in both directories
  old_files <- list.files(old_dir, pattern = pattern, full.names = FALSE)
  new_files <- list.files(new_dir, pattern = pattern, full.names = FALSE)

  all_files <- unique(c(old_files, new_files))

  results <- list()

  for (file in all_files) {
    old_path <- file.path(old_dir, file)
    new_path <- file.path(new_dir, file)

    if (!file.exists(old_path)) {
      # Entire file is new - all endpoints are "added"
      tryCatch({
        if (!exists("openapi_to_spec")) {
          suppressMessages({
            source(here::here("dev/endpoint_eval/00_config.R"))
            source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
            source(here::here("dev/endpoint_eval/06_param_parsing.R"))
            source(here::here("dev/endpoint_eval/04_openapi_parser.R"))
          })
        }
        new_json <- jsonlite::fromJSON(new_path, simplifyVector = FALSE)
        new_spec <- suppressMessages(openapi_to_spec(new_json))

        results[[file]] <- list(
          schema_file = file,
          added = new_spec %>% select(route, method, summary),
          removed = tibble(route = character(), method = character(), summary = character()),
          modified = tibble(route = character(), method = character(), change_type = character(),
                           detail = character(), breaking = logical())
        )
      }, error = function(e) {
        results[[file]] <<- list(schema_file = file, error = as.character(e$message))
      })

    } else if (!file.exists(new_path)) {
      # Entire file removed - all endpoints are "removed"
      tryCatch({
        if (!exists("openapi_to_spec")) {
          suppressMessages({
            source(here::here("dev/endpoint_eval/00_config.R"))
            source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
            source(here::here("dev/endpoint_eval/06_param_parsing.R"))
            source(here::here("dev/endpoint_eval/04_openapi_parser.R"))
          })
        }
        old_json <- jsonlite::fromJSON(old_path, simplifyVector = FALSE)
        old_spec <- suppressMessages(openapi_to_spec(old_json))

        results[[file]] <- list(
          schema_file = file,
          added = tibble(route = character(), method = character(), summary = character()),
          removed = old_spec %>% select(route, method, summary),
          modified = tibble(route = character(), method = character(), change_type = character(),
                           detail = character(), breaking = logical())
        )
      }, error = function(e) {
        results[[file]] <<- list(schema_file = file, error = as.character(e$message))
      })

    } else {
      # Both exist - run diff
      results[[file]] <- diff_single_schema(old_path, new_path)
    }
  }

  # Filter out schemas with zero changes
  results <- purrr::keep(results, function(r) {
    if (!is.null(r$error)) return(TRUE)  # Keep errors
    nrow(r$added) > 0 || nrow(r$removed) > 0 || nrow(r$modified) > 0
  })

  results
}

# ------------------------------------------------------------------------------
# Markdown Formatting
# ------------------------------------------------------------------------------

#' Format diff results as markdown for PR body injection
#'
#' @param diff_results Output from diff_schemas()
#' @return Markdown string
format_diff_markdown <- function(diff_results) {
  if (length(diff_results) == 0) {
    return("No endpoint-level changes detected.")
  }

  # Aggregate counts
  total_added <- sum(sapply(diff_results, function(r) nrow(r$added %||% tibble())))
  total_removed <- sum(sapply(diff_results, function(r) nrow(r$removed %||% tibble())))
  total_modified <- sum(sapply(diff_results, function(r) nrow(r$modified %||% tibble())))

  # Collect breaking and non-breaking changes
  breaking_changes <- list()
  nonbreaking_changes <- list()

  for (schema_name in names(diff_results)) {
    result <- diff_results[[schema_name]]

    # Handle errors
    if (!is.null(result$error)) {
      breaking_changes <- c(breaking_changes, list(tibble(
        schema = schema_name,
        endpoint = "ERROR",
        change = "Parse error",
        detail = result$error
      )))
      next
    }

    # Removed endpoints are breaking
    if (nrow(result$removed) > 0) {
      for (i in seq_len(nrow(result$removed))) {
        breaking_changes <- c(breaking_changes, list(tibble(
          schema = schema_name,
          endpoint = paste(result$removed$method[i], result$removed$route[i]),
          change = "Removed",
          detail = "Endpoint no longer exists"
        )))
      }
    }

    # Added endpoints are non-breaking
    if (nrow(result$added) > 0) {
      for (i in seq_len(nrow(result$added))) {
        nonbreaking_changes <- c(nonbreaking_changes, list(tibble(
          schema = schema_name,
          endpoint = paste(result$added$method[i], result$added$route[i]),
          change = "Added",
          detail = "New endpoint"
        )))
      }
    }

    # Modified endpoints - classify by breaking flag
    if (nrow(result$modified) > 0) {
      for (i in seq_len(nrow(result$modified))) {
        entry <- tibble(
          schema = schema_name,
          endpoint = paste(result$modified$method[i], result$modified$route[i]),
          change = "Modified",
          detail = result$modified$detail[i]
        )

        if (result$modified$breaking[i]) {
          breaking_changes <- c(breaking_changes, list(entry))
        } else {
          nonbreaking_changes <- c(nonbreaking_changes, list(entry))
        }
      }
    }
  }

  # Build markdown
  md <- character()

  md <- c(md, "### Endpoint Changes\n")
  md <- c(md, sprintf("**Summary:** %d endpoints added, %d removed, %d modified across %d schemas\n",
                      total_added, total_removed, total_modified, length(diff_results)))

  # Breaking changes section
  if (length(breaking_changes) > 0) {
    md <- c(md, "\n#### Breaking Changes\n")
    md <- c(md, "| Schema | Endpoint | Change | Detail |")
    md <- c(md, "|--------|----------|--------|--------|")

    breaking_df <- bind_rows(breaking_changes)
    for (i in seq_len(nrow(breaking_df))) {
      md <- c(md, sprintf("| %s | %s | %s | %s |",
                          breaking_df$schema[i],
                          breaking_df$endpoint[i],
                          breaking_df$change[i],
                          breaking_df$detail[i]))
    }
  }

  # Non-breaking changes section
  if (length(nonbreaking_changes) > 0) {
    md <- c(md, "\n#### Non-Breaking Changes\n")
    md <- c(md, "| Schema | Endpoint | Change | Detail |")
    md <- c(md, "|--------|----------|--------|--------|")

    nonbreaking_df <- bind_rows(nonbreaking_changes)
    for (i in seq_len(nrow(nonbreaking_df))) {
      md <- c(md, sprintf("| %s | %s | %s | %s |",
                          nonbreaking_df$schema[i],
                          nonbreaking_df$endpoint[i],
                          nonbreaking_df$change[i],
                          nonbreaking_df$detail[i]))
    }
  }

  paste(md, collapse = "\n")
}

# ------------------------------------------------------------------------------
# CLI Entrypoint (when sourced from CI)
# ------------------------------------------------------------------------------

if (sys.nframe() == 0) {
  # Parse command-line arguments
  args <- commandArgs(trailingOnly = TRUE)
  old_dir <- if (length(args) >= 1) args[1] else "schema_old"
  new_dir <- if (length(args) >= 2) args[2] else "schema"

  # Run diff
  cat("Diffing schemas...\n")
  cat(sprintf("Old: %s\n", old_dir))
  cat(sprintf("New: %s\n", new_dir))

  results <- diff_schemas(old_dir, new_dir)

  # Generate markdown report
  markdown <- format_diff_markdown(results)

  # Write to file
  writeLines(markdown, "schema_diff_report.md")
  cat("Report written to: schema_diff_report.md\n")

  # Calculate counts for CI
  breaking_count <- 0
  nonbreaking_count <- 0

  for (result in results) {
    if (!is.null(result$error)) {
      breaking_count <- breaking_count + 1
      next
    }

    # Removed endpoints are breaking
    breaking_count <- breaking_count + nrow(result$removed)

    # Added endpoints are non-breaking
    nonbreaking_count <- nonbreaking_count + nrow(result$added)

    # Modified endpoints - count by breaking flag
    if (nrow(result$modified) > 0) {
      breaking_count <- breaking_count + sum(result$modified$breaking)
      nonbreaking_count <- nonbreaking_count + sum(!result$modified$breaking)
    }
  }

  # Output counts for CI parsing
  cat(sprintf("BREAKING_COUNT=%d\n", breaking_count))
  cat(sprintf("NONBREAKING_COUNT=%d\n", nonbreaking_count))
}
