#' Search by string
#'
#' @param query Vector of strings
#' @param request_method String: 'GET' or 'POST'. Defaults to 'GET'.
#' @param search_method 'exact', 'starts', or 'contains'. Defaults to 'exact'.
#' @details This function checks the `run_debug` environment variable, which can be
#' set with `run_debug()`. If `TRUE`, it will perform a dry run and return the
#' request objects instead of executing them.
#'
#' @returns A data frame of search results.
#' @export
ct_search <- function(query, request_method = "GET", search_method = "exact") {
  # 1. Input validation and setup
  query_vector <- unique(as.vector(query))
  
  search_method <- rlang::arg_match(search_method, values = c('exact', 'starts', 'contains'))
  request_method <- rlang::arg_match(request_method, values = c('GET', 'POST'))
  
  # Informative CLI output
  cli::cli_rule(left = 'String search options')
  cli::cli_dl(items = c(
    'Compound count' = "{length(query_vector)}",
    'Search type' = "{search_method}"
  ))
  cli::cli_end()
  cli::cat_line()
  
  # 2. Prepare requests
  
  # Determine API path from search method
  path <- switch(search_method,
    "exact" = "chemical/search/equal/",
    "starts" = "chemical/search/start-with/",
    "contains" = "chemical/search/contain/")
  
  # Base request object
  base_req <- httr2::request(Sys.getenv('burl')) %>%
    httr2::req_headers(
      accept = "application/json",
      `x-api-key` = ct_api_key()
    ) %>%
    httr2::req_url_path_append(path)
  
  # Prepare search values (handle CAS numbers, etc.)
  search_values_df <- tibble::enframe(query_vector, name = NULL, value = 'raw_search') %>%
    dplyr::mutate(
      cas_chk = stringr::str_remove(.data$raw_search, "^0+"),
      cas_chk = stringr::str_remove_all(.data$cas_chk, "-"),
      # ! NOTE Swapped in native as_cas function
      cas_chk = as_cas(.data$cas_chk),
      searchValue = stringr::str_to_upper(.data$raw_search) %>%
      # ! NOTE Swaps out apostrophes to single quotes; seems to be best practice
      stringr::str_replace_all(., c('-' = ' ', '\\u00b4' = "'")),
      searchValue = dplyr::case_when(
        !is.na(.data$cas_chk) ~ .data$cas_chk,
        .default = .data$searchValue
      )
    ) %>%
    dplyr::select("raw_search", "searchValue") %>%
    dplyr::filter(!is.na(.data$searchValue))
  
  # Build list of requests
  reqs <- list()
  if (request_method == 'GET') {
    # Create a named list of requests, one for each search value
    # Names are used later to map results back to the original query
    reqs <- purrr::map(
      stats::setNames(search_values_df$searchValue, search_values_df$raw_search),
      function(val) {
        req <- base_req %>%
          httr2::req_url_path_append(URLencode(val))
        
        if (search_method %in% c("starts", "contains")) {
          req <- req %>% httr2::req_url_query(top = '500')
        }
        req
      }
    )
  } else if (request_method == 'POST') {
    cli::cli_abort('POST requests are not supported at this time.')
  }
  
  # 3. Execute requests and process responses
  
  if (isTRUE(as.logical(Sys.getenv('run_debug')))) {
    return(purrr::map(reqs, httr2::req_dry_run))
  }
  
  if (length(reqs) == 0) {
    cli::cli_alert_info("No valid queries to perform.")
    return(tibble::tibble())
  }
  
  resps <- httr2::req_perform_sequential(reqs, on_error = 'continue', progress = TRUE) %>% 
    set_names(names(reqs))


# Parsing response -------------------------------------------------------

  
  # Process all responses, creating a row of NAs for failed/empty ones.
  results <- purrr::map(resps, function(resp) {

    # `resp` from req_perform_sequential can be a response, an error, or NULL.
    # If it's an httr2 error condition, extract the response object from it.
    # This robustly handles the case where an error condition is returned
    # instead of the response object itself.
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
          purrr::compact() %>%
          purrr::map(~ purrr::map_if(.x, is.null, ~ NA_character_)) %>%
          dplyr::bind_rows()
      )
    }
    
    # ! 400: Bad Request - attempt to parse as success, otherwise treat as empty/error
    if (status == 400) {
      body <- try(httr2::resp_body_json(resp), silent = TRUE)
      
      if (inherits(body, "try-error") || length(body) == 0) {
        # If body is not valid JSON or is empty, it's truly a bad request with no data.
        msg <- if (inherits(body, "try-error")) {
          "Response body could not be parsed as JSON."
        } else {
          "Response body was empty."
        }
        cli::cli_warn("Query resulted in status 400 (Bad Request) with no parsable data. {msg}")
        return(tibble::tibble()) # Return empty tibble if no data
      } else {
        # If body is valid and not empty, process it like a 2xx success.
        # No warning here, as it's treated as a successful data retrieval.
        return(
          body %>%
            purrr::compact() %>%
            purrr::map(~ purrr::map_if(.x, is.null, ~ NA_character_)) %>%
            # ! NOTE Discards other list-elements aside from suggestions
            purrr::keep_at(., 'suggestions') %>% 
            tibble::as_tibble() %>% 
            unnest_longer(., col = suggestions)
        )
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
    
    # Fallback for unhandled cases
    # return(tibble::tibble())
  }) %>% purrr::list_rbind(names_to = "raw_search")

  return(results)
}

# ! Testing
# q1 <- ct_search('benquine')

# q1 <- ct_search(c('benzene', 'benquine', '50-00-1'))

# ct_search(c('benzene', 'benquine', '50001'))

# ct_search('54115', search_method = 'starts')

# ct_search(query = c(
#   'Acetone Peroxide',
#   'HMTD',
#   'Mercury(II) Fulminate',
#   'Nitroglycerin',
#   'PLX',
#   'Trinitrotoluene',
#   'RDX',
#   'HMX',
#   'Ammonium Nitrate',
#   'Picric Acid'
# )) %>% print(n = Inf)