#' Generic API Request Function
#'
#' This is a centralized template function used by nearly all `ct_*` functions
#' to perform API requests. it handles normalization, batching, authentication,
#' error handling, and data tidying.
#'
#' @param query A character vector or list of items to be queried (e.g., DTXSIDs, CASRNs).
#' @param endpoint The API endpoint path (e.g., "hazard", "chemical/fate").
#' @param method The HTTP method to use: "POST" (default for bulk searches) or "GET".
#' @param server Either a Global environment variable name (e.g., 'ctx_burl') or a direct URL string.
#' @param batch_limit The number of items to send per request. Bulk POSTs usually use 100-1000.
#'        If set to 1, GET requests will append the query item directly to the URL path.
#' @param ... Additional parameters:
#'        - If method is "POST": Added as query parameters to the URL.
#'        - If method is "GET" and batch_limit is 1: Unnamed arguments are appended as path fragments; 
#'          named arguments are added as query parameters.
#'        - If method is "GET" and batch_limit > 1: Added as query parameters to the URL.
#'
#' @return A tidy tibble. If no results are found, returns an empty tibble.
#' @export
generic_request <- function(query, endpoint, method = "POST", server = 'ctx_burl', batch_limit = NULL, ...) {

  # --- 1. Base URL Resolution ---
  # We check if 'server' refers to an environment variable (like 'ctx_burl').
  # If it doesn't exist, we assume 'server' is the literal URL.
  base_url <- Sys.getenv(server, unset = server)
  if (base_url == "") base_url <- server

  # --- 2. Input Normalization ---
  # Ensure the query is a unique character vector without NAs or empty strings.
  if(purrr::is_list(query) && !is.data.frame(query)) {
    query <- as.character(unlist(query, use.names = FALSE))
  }
  query <- unique(as.vector(query))
  query <- query[!is.na(query) & query != ""]

  if (length(query) == 0) cli::cli_abort("Query must be a character vector.")

  # --- 3. Batching Preparation ---
  # API endpoints often have limits (e.g., 200 or 1000 items per POST).
  # We split the query into chunks based on the batch_limit.
  if (is.null(batch_limit)) {
    batch_limit <- as.numeric(Sys.getenv("batch_limit", "1000"))
  }
  
  mult_count <- ceiling(length(query) / batch_limit)
  
  if (length(query) > batch_limit) {
    query_list <- split(
      query,
      rep(1:mult_count, each = batch_limit, length.out = length(query))
    )
  } else {
    query_list <- list(query)
  }

  # Check environment flags for logging/debugging
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    cli::cli_rule(left = paste('Generic Request:', endpoint))
    cli::cli_dl(
      c(
        'Number of items' = '{length(query)}',
        'Number of batches' = '{mult_count}',
        'Method' = '{method}'
      )
    )
    cli::cli_rule()
    cli::cli_end()
  }

  # --- 4. Request Construction ---
  # Create a list of httr2 request objects, one for each batch.
  req_list <- purrr::map(
    query_list,
    function(query_part) {
      req <- httr2::request(base_url) %>%
        httr2::req_url_path_append(endpoint) %>%
        httr2::req_headers(
          Accept = "application/json",
          `x-api-key` = ct_api_key()
        )

      # Implementation for POST requests (Typically bulk searches)
      if (toupper(method) == "POST") {
        req <- req %>% 
          httr2::req_method("POST") %>%
          httr2::req_body_json(query_part, auto_unbox = FALSE) %>%
          # Add ellipsis arguments as query params (e.g., projection="all")
          httr2::req_url_query(...)
      } 
      # Implementation for GET requests
      else {
        req <- req %>% httr2::req_method("GET")
        
        # Scenario A: Path-based GET (one item at a time, e.g., /assay/ID)
        if (batch_limit == 1) {
          req <- req %>% httr2::req_url_path_append(as.character(query_part))
          
          # Separate named vs unnamed ellipsis arguments
          args <- list(...)
          named_indices <- names(args) != "" & !is.null(names(args))
          
          # Append unnamed args to the URL path (e.g., /assay/ID/similarity)
          if (any(!named_indices)) {
            for (val in args[!named_indices]) {
              req <- req %>% httr2::req_url_path_append(as.character(val))
            }
          }
          # Add named args as query parameters (e.g., ?top=500)
          if (any(named_indices)) {
            req <- req %>% httr2::req_url_query(!!!args[named_indices])
          }
        } 
        # Scenario B: Parameter-based GET (bulk fetch via query string)
        else {
          req <- req %>% httr2::req_url_query(search = paste(query_part, collapse = ","), ...)
        }
      }
      
      return(req)
    }
  )

  # --- 5. Debugging Hook ---
  # If 'run_debug' is TRUE, we return a dry run of the first request instead of executing.
  if (run_debug) {
    return(req_list %>% purrr::pluck(1) %>% httr2::req_dry_run())
  }

  # --- 6. Execution ---
  # Perform requests. Use sequential execution for batches to avoid hitting rate limits too hard.
  if (length(req_list) > 1) {
    resp_list <- req_list %>%
      httr2::req_perform_sequential(on_error = 'continue', progress = run_verbose)
  } else {
    resp_list <- list(httr2::req_perform(req_list[[1]]))
  }

  # --- 7. Response Processing ---
  # Extract JSON bodies and handle HTTP errors gracefully.
  body_list <- resp_list %>%
    purrr::map2(query_list, function(r, qp) {
      # Handle potential httr2 error objects
      if (inherits(r, "httr2_error")) r <- r$resp
      if (!inherits(r, "httr2_response")) return(NULL)
      
      status <- httr2::resp_status(r)
      if (status < 200 || status >= 300) {
        cli::cli_warn("API request to {.val {endpoint}} failed for {.val {qp[1]}} with status {status}")
        return(NULL)
      }

      return(httr2::resp_body_json(r))
    }) %>%
    # Flatten the list of responses (one list of data per batch) into one single list
    purrr::list_flatten()

  if (length(body_list) == 0) {
    cli::cli_alert_warning("No results found for the given query in {.val {endpoint}}.")
    return(tibble::tibble())
  }

  # --- 8. Tidy Conversion ---
  # Convert the parsed JSON (list of lists) into a tidy tibble.
  res <- body_list %>%
    purrr::map(function(x) {
      if (is.list(x) && length(x) > 0) {
        # Replace NULLs with NA so they don't disappear during tibble conversion
        x[purrr::map_lgl(x, is.null)] <- NA
        return(tibble::as_tibble(x))
      } else if (is.null(x) || length(x) == 0) {
        return(NULL)
      } else {
        # Primitive values (strings/numbers) are wrapped into a 'value' column
        return(tibble::tibble(value = x))
      }
    }) %>%
    purrr::list_rbind()

  return(res)
}
