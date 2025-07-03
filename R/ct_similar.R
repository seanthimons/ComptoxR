#' @title Get Similar Compounds by DTXSID
#' 
ct_similar <- function(query, similarity = 0.8) {
  # Determine if debug mode is active from environment variable
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  # Determine if verbose mode is active from environment variable
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))
  # Get base URL from environment variable

  # Validate similarity threshold
  if (similarity < 0 || similarity > 1) {
    cli::cli_abort("Similarity threshold must be between 0 and 1.")
  }

  if(!is.numeric(similarity)) {
    cli::cli_abort("Similarity threshold must be a numeric value.")
  }

  # Display debugging information about the query payload
  cli::cli_rule(left = "Similar compounds payload options")
  cli::cli_dl(c(
    "Number of queries" = "{length(query)}",
    "Similarity threshold" = "{similarity}"
  ))
  cli::cli_rule()
  cli::cli_end()

  # Inform user if debug mode is active
  if (run_debug) {
    cli::cli_alert_info("Debug/dry-run mode is active. No actual HTTP requests will be made.")
  }

#Maps over the query list to construct the request for each query
req_list <- map(query, ~{

  # Construct the HTTP request object
    
  req <- request('https://comptox.epa.gov/dashboard-api/') %>%
      req_url_path_append('similar-compound/by-dtxsid/') %>%
      req_url_path_append(.x) %>%
      req_url_path_append(similarity)
  
# If in debug mode, return a dry-run of the request
  if (run_debug) {
      return(req_dry_run(req))
    }
  return(req)
})

resp <- req_perform_sequential(req_list, on_error = "continue", progress = TRUE) %>% 
  set_names(query)

results <- resp %>% 
  resps_successes() %>% 
  map(., ~{
    if (is.null(.x)) {
      return(tibble())
    }else{
      resp_body_json(.x) %>% 
        map(., as_tibble) %>% 
        list_rbind()
    }
    
  }) %>% list_rbind(names_to = 'query')

  return(results)
}
