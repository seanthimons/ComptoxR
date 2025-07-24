#' Search for synonyms by DTXSID
#'
#' @param query Vector of DTXSIDs (strings).
#' @param request_method String: 'GET' or 'POST'. Defaults to 'GET'.
#' @details This function checks the `run_debug` environment variable, which can be
#' set with `run_debug()`. If `TRUE`, it will perform a dry run and return the
#' request objects instead of executing them.
#'
#' @returns A data frame of synonym results.
#' @export
ct_synonym <- function(query, request_method = "GET") {
  
  # 1. Input validation and setup
  query_vector <- unique(as.vector(query))
  request_method <- rlang::arg_match(request_method, values = c("GET", "POST"))
  
  # Informative CLI output
  cli::cli_rule(left = 'Synonym search options')
  cli::cli_dl(items = c(
    'DTXSID count' = "{length(query_vector)}",
    'Request method' = "{request_method}"
  ))
  cli::cli_end()
  cli::cat_line()
  
  # 2. Prepare requests
  path_prefix <- "chemical/synonym/search/by-dtxsid/"
  
  base_req <- httr2::request(Sys.getenv('burl')) %>%
    httr2::req_headers(
      accept = "application/json",
      `x-api-key` = ct_api_key()
    ) %>%
    httr2::req_url_path_append(path_prefix)
  
  # Build list of requests
  reqs <- list()

  if (request_method == "GET") {
  # Names are used later to map results back to the original query
  reqs <- purrr::map(
    stats::setNames(query_vector, query_vector),
    function(dtxsid) {
      base_req %>%
        httr2::req_url_path_append(URLencode(dtxsid))
    }
  )
  }
	if (request_method == "POST") {
    # Split queries into chunks of 100
		# ! NOTE: Documentation site usually says 200, other endpoints have been discovered to be ~100
    query_chunks <- split(
      query_vector,
      ceiling(seq_along(query_vector) / 100)
      )

    reqs <- purrr::map(query_chunks, function(chunk) {
      base_req %>%
      httr2::req_body_json(
        body = list(dtxsids = chunk)
        )
    })
	}
    
  # 3. Execute requests and process responses
  
  if (isTRUE(as.logical(Sys.getenv('run_debug')))) {
    return(purrr::map(reqs, httr2::req_dry_run))
  }
  
  if (length(reqs) == 0) {
    cli::cli_alert_info("No valid DTXSIDs to perform synonym search.")
        return(tibble::tibble())
      }

  resps <- httr2::req_perform_sequential(reqs, on_error = 'continue', progress = TRUE)

  # GET response parsing
  if (request_method == "GET") {
    resps <- set_names(resps, names(reqs))

    # Process all responses, creating a row of NAs for failed/empty ones.
    results <- purrr::map(resps, function(resp) {
      # `resp` from req_perform_sequential can be a response, an error, or NULL.
      # If it's an httr2 error condition, extract the response object from it.
      if (inherits(resp, "httr2_error")) {
        resp <- resp$resp
    }
    
      # Handle cases where the request failed completely (e.g., timeout) or
      # where `resp` was an error condition without a response object.
      if (!inherits(resp, "httr2_response")) {
        msg <- if (is.null(resp)) "No response received from server." else as.character(resp)
        cli::cli_warn("A request failed: {msg}")
        return(tibble::tibble(error = "Request failed", message = msg))
    }
      status <- httr2::resp_status(resp)
      # ! 2xx: Success
      if (status < 300) {
        body <- httr2::resp_body_json(resp)
        if (length(body) == 0) {
          return(tibble::tibble()) # No results found, return empty tibble
    }
        # Process body like a successful response
        return(
          body %>%
            purrr::discard(., names(.) %in% c('pcCode', 'dtxsid')) %>%
            purrr::map(~ purrr::map_if(.x, is.null, ~ NA_character_)) %>%
            dplyr::bind_rows()
        )
}

      # ! 400: Bad Request - attempt to parse as success, otherwise treat as empty/error
      if (status == 400) {
        body <- try(httr2::resp_body_json(resp), silent = TRUE)

        if (inherits(body, "try-error") || length(body) == 0) {
          msg <- if (inherits(body, "try-error")) {
            "Response body could not be parsed as JSON."
          } else {
            "Response body was empty."
          }
          cli::cli_warn("Query resulted in status 400 (Bad Request) with no parsable data. {msg}")
          return(tibble::tibble()) # Return empty tibble if no data
        } else {
          cli::cli_warn("Query resulted in status 400 (Bad Request). Body: {jsonlite::toJSON(body, auto_unbox = TRUE)}")
          return(tibble::tibble())
        }
      }

      # ! 404: Not Found - a common outcome for searches, not a "failure"
      if (status == 404) {
        return(tibble::tibble()) # No results found, return empty tibble
      }

      # ! Other 4xx and 5xx errors
      if (status >= 400) {
        msg <- httr2::resp_status_desc(resp)
        cli::cli_warn("Query failed with status {status}: {msg}")
        return(tibble::tibble(error = msg, message = paste("HTTP status", status)))
      }
    }) %>%
      purrr::list_rbind(names_to = "raw_query")
  }

  if (request_method == "POST") {
    # Re-create the chunks to map responses back to their original queries
    query_chunks <- split(
      query_vector,
      ceiling(seq_along(query_vector) / 200)
    )

    # Process responses chunk by chunk, creating a list of tibbles
    results <- purrr::map2(resps, query_chunks, function(resp, chunk) {
      if (inherits(resp, "httr2_error")) {
        resp <- resp$resp
      }

      if (!inherits(resp, "httr2_response")) {
        msg <- if (is.null(resp)) {
          "No response received from server."
        } else {
          as.character(resp)
        }
        cli::cli_warn("A request chunk failed: {msg}")
        return(tibble::tibble(
          raw_query = chunk,
          error = "Request failed",
          message = msg
        ))
      }
  
      status <- httr2::resp_status(resp)

      # For any non-successful status, apply an error to all queries in the chunk
      if (status >= 300) {
        msg <- httr2::resp_status_desc(resp)
        cli::cli_warn("Query chunk failed with status {status}: {msg}")
        return(tibble::tibble(
          raw_query = chunk,
          error = msg,
          message = paste("HTTP status", status)
        ))
      }

      # On success (2xx), parse the body.
      body <- httr2::resp_body_json(resp)
      if (length(body) == 0) {
        return(tibble::tibble()) # No results for this chunk
      }

      if (length(body) != length(chunk)) {
        cli::cli_warn("POST response length ({length(body)}) does not match query chunk size ({length(chunk)}). Results for this chunk are being discarded.")
        return(tibble::tibble(raw_query = chunk, error = "Response/Query mismatch", message = "Inconsistent number of results in response body."))
      }

      names(body) <- chunk

      body %>%
        purrr::map(function(result_for_one_dtxsid) {
          if (length(result_for_one_dtxsid) == 0) return(NULL)
          result_for_one_dtxsid %>%
            purrr::discard(., names(.) %in% c('pcCode', 'dtxsid')) %>%
            purrr::map(~ purrr::map_if(.x, is.null, ~ NA_character_)) %>%
            dplyr::bind_rows()
        }) %>%
        purrr::list_rbind(names_to = "raw_query")
    }) %>%
      # Row-bind the list of tibbles from each chunk into a single final tibble
      purrr::list_rbind()
  }

  return(results)
}
