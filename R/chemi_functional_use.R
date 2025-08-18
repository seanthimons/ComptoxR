#' Fetch Chemical Functional Use Information
#'
#' This function queries the chemical annotation API to retrieve functional use
#' data for a given set of chemical identifiers (DTXSIDs). It strictly follows
#' the design principles of the `httr2` package for clarity, robustness, and
#' explicit error handling. It is controlled by environment variables for base
#  URL, API key, and operational modes (debug/verbose).
#'
#' @param query A character vector of one or more DTXSIDs to query.
#' @param path The specific API endpoint path for the functional use query.
#'   Defaults to the standard endpoint for DTXSID-based lookups.
#'
#' @return A `tibble` containing the aggregated functional use data for all
#'   successful queries. For queries that fail or return no data, the tibble
#'   will include rows with the original `dtxsid` and an `error` message or
#'   `NA` values, ensuring the output is always a single, cohesive data frame.
#'
#' @section Environment Variables:
#' This function relies on the following environment variables:
#' \itemize{
#'   \item \code{burl}: The base URL for the API (e.g., "https://api.example.com").
#'   \item \code{CT_API_KEY}: Your secret API key for authentication.
#'   \item \code{run_debug}: If "TRUE", the function performs a dry run, printing
#'     the request structure without sending it.
#'   \item \code{run_verbose}: If "TRUE", the function prints progress messages
#      for each query item.
#' }
chemi_functional_use <- function(query, path = "/api/amos/functional_uses_for_dtxsid") {
  # --- 1. Environment Variable & Input Validation ---
  burl <- Sys.getenv("burl", unset = NA)
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  # Helper function to retrieve API key securely from environment variables.
  ct_api_key <- function() {
    key <- Sys.getenv("CT_API_KEY", unset = NA)
    if (is.na(key)) {
      cli_abort(
        "API key not found. Please set the {.envvar CT_API_KEY} environment variable."
      )
    }
    return(key)
  }

  if (is.na(burl)) {
    cli_abort("Base URL is not set. Please set the {.envvar burl} environment variable.")
  }
  if (!is.character(query) || length(query) == 0) {
    cli_abort("{.arg query} must be a non-empty character vector of DTXSIDs.")
  }

  # --- 2. Pre-request CLI Messaging ---
  cli_rule(left = "DTXSID payload options")
  cli_dl(c("Number of compounds" = "{length(query)}"))
  cli_rule()

  # --- 3. Debug (Dry-Run) Mode ---
  if (run_debug) {
    cli_alert_info("Debug mode is ON. Performing a dry run for the first query item.")

    # Build a representative request to display.
    req <- request(burl) %>%
      req_url_path_append(path) %>%
      req_url_path_append(query[1]) %>% # Use first item as an example.
      req_headers("x-api-key" = ct_api_key()) %>%
      req_timeout(30) %>%
      req_accept_json()

    return(req_dry_run(req))
  }

  # --- 4. Core Request Logic (Helper Function) ---
  # This helper processes a single item, handling all request, response, and error
  # logic. It is designed to always return a tibble for easy aggregation.
  process_single_item <- function(item, index, total) {
    if (run_verbose) {
      cli_alert_info("Processing query {index} of {total}: item_id = {.val {item}}")
    }

    # Build the request chain using httr2's idiomatic style.
    req <- request(burl) %>%
      req_url_path_append(path, item) %>%
      req_headers("x-api-key" = ct_api_key()) %>%
      req_timeout(30) %>%
      req_accept_json() %>%
      req_error(is_error = ~ FALSE) # Handle HTTP errors manually.

    # Safely perform the request to catch R-level errors (e.g., network issues).
    resp_safe <- safely(req_perform)(req)

    # Handle R-level errors
    if (!is.null(resp_safe$error)) {
      cli_warn("Request for {.val {item}} failed: {resp_safe$error$message}")
      return(tibble(dtxsid = item, error = as.character(resp_safe$error$message)))
    }

    resp <- resp_safe$result

    # Handle HTTP-level errors (e.g., 4xx, 5xx status codes).
    if (resp_is_error(resp)) {
      error_detail <- safely(~ resp_body_json(resp)$detail)()$result
      error_msg <- if (!is.null(error_detail)) error_detail else "No details provided."
      cli_warn("HTTP error for {.val {item}}: {resp$status_code} {resp_status_desc(resp)}.")
      return(tibble(dtxsid = item, error = glue::glue("HTTP {resp$status_code}: {error_msg}")))
    }

    body <- resp_body_json(resp)

    # Handle successful requests that return no specific data (e.g., an empty JSON array `[]`).
    if (length(body) == 0) {
      cli_alert_success("Query for {.val {item}} successful, no functional uses found.")
      return(tibble(dtxsid = item, functional_use = NA_character_, source = NA_character_, error = NA_character_))
    }

    # Process the successful response body into a clean tibble.
    cli_alert_success("Successfully retrieved and processed data for {.val {item}}.")
    bind_rows(body) %>%
      mutate(dtxsid = item, error = NA_character_) %>%
      select(dtxsid, everything())
  }

  # --- 5. Execution and Aggregation ---
  # Use imap to iterate, then bind the resulting list of tibbles into one.
  results_list <- imap(query, ~ process_single_item(.x, .y, total = length(query)))
  final_tibble <- list_rbind(results_list)

  cli_rule(left = "Processing Complete")
  cli_alert_success("Finished processing all {length(query)} queries.")

  if (nrow(final_tibble) == 0) {
    cli_alert_warning("No data was returned from any of the queries.")
  }

  return(final_tibble)
}
