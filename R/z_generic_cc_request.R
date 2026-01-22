#' Generic CAS Common Chemistry API Request Function
#'
#' This is a specialized wrapper for CAS Common Chemistry API requests.
#' It handles the specific authentication (cc_api_key) and server configuration
#' for the Common Chemistry API endpoints.
#'
#' @param endpoint The API endpoint path (e.g., "detail", "search", "export").
#' @param method The HTTP method to use: "GET" (default) or "POST".
#' @param server Environment variable name for the base URL. Defaults to "cc_burl".
#' @param auth Boolean; whether to include the API key header. Defaults to TRUE.
#' @param tidy Boolean; whether to convert the result to a tidy tibble. Defaults to TRUE.
#'        If FALSE, returns a cleaned list structure.
#' @param content_type Expected response content type. Defaults to "application/json".
#' @param ... Additional parameters passed as query parameters to the API.
#'
#' @return Depends on content_type and tidy parameter:
#'         - JSON with tidy=TRUE: A tidy tibble.
#'         - JSON with tidy=FALSE: A cleaned list structure.
#'         - text/plain: A character string.
#'         If no results are found, returns an empty tibble or list.
#' @export
generic_cc_request <- function(endpoint, method = "GET", server = "cc_burl", 
                               auth = TRUE, tidy = TRUE, content_type = "application/json", ...) {
  
  # --- 1. Base URL Resolution ---
  base_url <- Sys.getenv(server, unset = server)
  if (base_url == "") base_url <- server
  
  # Check environment flags for logging/debugging
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))
  
  if (run_verbose) {
    cli::cli_rule(left = paste('Generic CC Request:', endpoint))
    cli::cli_dl(c('Method' = '{method}'))
    cli::cli_rule()
    cli::cli_end()
  }
  
  # --- 2. Capture ellipsis arguments ---
  ellipsis_args <- list(...)
  
  # --- 3. Request Construction ---
  req <- httr2::request(base_url) %>%
    httr2::req_url_path_append(endpoint) %>%
    httr2::req_method(toupper(method)) %>%
    httr2::req_headers(Accept = content_type)
  
  # Add CC API key authentication
  if (auth) {
    req <- req %>% httr2::req_headers(`x-api-key` = cc_api_key())
  }
  
  # Add query parameters
  if (length(ellipsis_args) > 0) {
    req <- req %>% httr2::req_url_query(!!!ellipsis_args)
  }
  
  # --- 4. Debugging Hook ---
  if (run_debug) {
    return(httr2::req_dry_run(req))
  }
  
  # --- 5. Execution ---
  resp <- httr2::req_perform(req)
  
  # --- 6. Response Processing ---
  status <- httr2::resp_status(resp)
  if (status < 200 || status >= 300) {
    cli::cli_abort("CAS Common Chemistry API request to {.val {endpoint}} failed with status {status}")
  }
  
  # Handle different content types
  is_text <- grepl("^text/plain", content_type)
  is_json <- !is_text
  
  if (is_text) {
    return(httr2::resp_body_string(resp))
  }
  
  # JSON response handling
  body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  
  if (length(body) == 0) {
    cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
    if (tidy) {
      return(tibble::tibble())
    } else {
      return(list())
    }
  }
  
  # --- 7. Output Formatting ---
  if (!tidy) {
    # Basic cleanup: replace NULLs with NA in list elements
    if (is.list(body) && length(body) > 0) {
      body[purrr::map_lgl(body, is.null)] <- NA
    }
    return(body)
  }
  
  # --- 8. Tidy Conversion ---
  # Handle single object vs array of objects
  if (is.list(body) && !is.null(names(body))) {
    # Single object response
    body[purrr::map_lgl(body, is.null)] <- NA
    res <- tryCatch(
      tibble::as_tibble(body),
      error = function(e) tibble::tibble(data = list(body))
    )
  } else if (is.list(body)) {
    # Array of objects
    res <- body %>%
      purrr::map(function(x) {
        if (is.list(x) && length(x) > 0) {
          x[purrr::map_lgl(x, is.null)] <- NA
          t_res <- tryCatch(
            tibble::as_tibble(x),
            error = function(e) tibble::tibble(data = list(x))
          )
          return(t_res)
        } else if (is.null(x) || length(x) == 0) {
          return(NULL)
        } else {
          return(tibble::tibble(value = x))
        }
      }) %>%
      purrr::list_rbind()
  } else {
    # Primitive value
    res <- tibble::tibble(value = body)
  }
  
  return(res)
}
