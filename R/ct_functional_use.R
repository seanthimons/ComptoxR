#' @title Retrieve Functional Use Probability by DTXSID
#'
#' @description
#' This function retrieves functional use probability data from the EPA's
#' Chemical Transformation Tool (CTT) API for a given DTXSID. It adheres to
#' robust, explicit, and chainable design principles using the `httr2` package,
#' prioritizing clarity, predictable behavior, and comprehensive error handling.
#'
#' @param query A character vector of DTXSIDs to query.
#'
#' @return A list or tibble containing the functional use probability data.
#'         If `RUN_DEBUG` is TRUE, returns the `httr2_request` object or dry-run output.
#'
#' @details
#' The base API URL is retrieved from the environment variable `burl`. The API
#' key is applied using `ct_api_key()`. The function handles debugging and
#' verbose output based on environment variables `RUN_DEBUG` and `RUN_VERBOSE`.
#' It constructs HTTP requests using `httr2`'s chainable syntax, checks for
#' HTTP errors, and parses successful JSON responses.
#' @export
ct_functional_use <- function(query, path) {
  run_debug <- as.logical(Sys.getenv("run_debug", FALSE))
  run_verbose <- as.logical(Sys.getenv("run_verbose", FALSE))

  base_url <- Sys.getenv("burl", unset = NA)
  if (is.na(base_url)) {
    cli::cli_alert_danger("Base URL 'burl' not found in environment variables.")
    stop("Base URL 'burl' not found in environment variables.")
  }

  cli::cli_rule(left = "<DTXSID> payload options")
  cli::cli_dl(c("Number of compounds" = "{length(query)}"))
  cli::cli_rule()
  cli::cli_end()

  if (run_debug) {
    cli::cli_alert_info("Debug mode is active. Performing dry run.")
  }

  make_request <- function(item, current_index = NULL, total_queries = NULL) {
    if (run_verbose && !is.null(current_index) && !is.null(total_queries)) {
      cli::cli_alert_info(
        "Processing query {current_index} of {total_queries}: item_id = {item}"
      )
    }

    request(base_url) %>%
      req_url_path_append(path) %>%
      req_url_query(dtxsid = item) %>%
      req_headers("x-api-key" = ct_api_key(), "accept" = "application/json") %>%
      req_timeout(30)
  }

  execute_request <- function(req) {
    if (run_debug) {
      req %>%
        req_dry_run()
    } else {
      req %>%
        req_perform()
    }
  }

  process_response <- function(resp) {
    if (run_debug) {
      return(resp)
    }

    if (resp_is_error(resp)) {
      cli::cli_alert_danger(
        "HTTP error: {resp_status(resp)} - {resp_body_string(resp)}"
      )
      return(NULL)
    } else {
      cli::cli_alert_success("Request successful.")
      json_body <- resp_body_json(resp)
      if (length(json_body) > 0) {
        as_tibble(json_body)
      } else {
        list()
      }
    }
  }

  results <- purrr::map(
    .x = query,
    .f = function(item) {
      req <- make_request(item)
      resp <- execute_request(req)
      process_response(resp)
    }
  )

  return(results)
}
