#' @title Retrieve ClassyFire classification by InChlKey from Wishart Lab
#' @description This function retrieves ClassyFire classification results for a
#'   given InChlKey from the Wishart Lab ClassyFire website.
#' @param query A character vector of InChlKeys to retrieve.
#' @param path The API endpoint path, relative to the base URL.
#' @returns A list containing the ClassyFire classification results.
#' @examples
#' \dontrun{
#' util_classyfire_wishart(query = "NKANXQFJJICGDU-QPLCGJKRSA-N")
#' }

util_classyfire_wishart <- function(query, path = "entities") {
  # ---------------------------------------------------------------------------
  # --- Error handling
  # ---------------------------------------------------------------------------

  # --- Check if query is missing
  if (missing(query)) {
    cli::cli_abort("The `query` argument is missing. Please provide an InChlKey.")
  }

  # --- Check if query is a character vector
  if (!is.character(query)) {
    cli::cli_abort("The `query` argument must be a character vector of InChlKeys.")
  }

  # ---------------------------------------------------------------------------
  # --- Get environment variables
  # ---------------------------------------------------------------------------
 
  run_debug <- as.logical(Sys.getenv("run_debug", unset = "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", unset = "FALSE"))

  # ---------------------------------------------------------------------------
  # --- Debugging information
  # ---------------------------------------------------------------------------
  cli::cli_rule(left = "ClassyFire Wishart payload options")
  cli::cli_dl(c(
    "Number of queries" = "{length(query)}"
    # ,"Base URL (ctx_burl)" = "{ctx_burl}",
    # "Path" = "{path}",
    # "Debug mode (run_debug)" = "{run_debug}",
    # "Verbose mode (run_verbose)" = "{run_verbose}"
  ))
  cli::cli_rule()
  cli::cli_end()

  # ---------------------------------------------------------------------------
  # --- Create the request wrapper
  # ---------------------------------------------------------------------------
  safe_get_wishart_result <- purrr::possibly(
    .f = function(current_query, current_index, total_queries) {
      if (run_verbose) {
        cli::cli_alert_info("({current_index}/{total_queries}) Retrieving classification for InChlKey: {current_query}")
      }

      # --- Build request ---
      req <-
        httr2::request('http://classyfire.wishartlab.com/') %>%
        httr2::req_url_path_append(path = glue::glue("{path}/{current_query}")) %>%
        httr2::req_headers(
          "Accept" = "application/json"
        ) %>%
        #httr2::req_timeout(10) %>% # Increased timeout for potential large responses
        httr2::req_retry(
          retry_on_failure = TRUE # Retry on failure
          ,max_tries = 5,
         # is_transient = ~ httr2::resp_is_transient(.x) || httr2::resp_status_class(.x) == "server"
        )

      # --- Handle debug mode (dry run) ---
      if (run_debug) {
        cli::cli_alert_info("Dry run for request:")
        httr2::req_dry_run(req)
        return(invisible(req)) # Return the request object in debug mode
      }

      # --- Perform request ---
      resp <- httr2::req_perform(req)

      # --- Validate response ---
      if (httr2::resp_is_error(resp)) {
        status_code <- httr2::resp_status(resp)
        cli::cli_alert_danger("({current_index}/{total_queries}) HTTP error {status_code} for InChlKey: {current_query}")
        cli::cli_alert_info("Response body: {.val {httr2::resp_body_string(resp)}}")
        return(NULL)
      }

      if (run_verbose) {
        cli::cli_alert_success("({current_index}/{total_queries}) Successfully retrieved result for InChlKey: {current_query}")
      }

      httr2::resp_body_json(resp)
    },
    otherwise = NA # Return NA for any unexpected R errors
  )

  # --- Map over the query ---
  results <- purrr::map(
    .x = query,
    .f = safe_get_wishart_result,
    current_index = seq_along(query),
    total_queries = length(query),
    .progress = TRUE
  )

  return(results)
}
