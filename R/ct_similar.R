#' @title Get Similar Compounds by DTXSID
#' 
#' @param query A character vector of DTXSIDs.
#' @param similarity The similarity threshold, a numeric value between 0 and 1. Optional, defaults to 0.8.
#'
#' @returns A tibble of similar compounds, or an empty tibble if no similar compounds are found.
#' @export
ct_similar <- function(query, similarity = 0.8) {

  #burl <- Sys.getenv('burl')
  # ! NOTE: The burl variable is hardcoded here until API is stable and has the endpoint. 
  
  burl <- 'https://comptox.epa.gov/dashboard-api/'
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))
  
  if (similarity < 0 || similarity > 1) {
    cli::cli_abort("Similarity threshold must be between 0 and 1.")
  }

  if(!is.numeric(similarity)) {
    cli::cli_abort("Similarity threshold must be a numeric value.")
  }

  cli::cli_rule(left = "Similar compounds payload options")
  cli::cli_dl(c(
    "Number of queries" = "{length(query)}",
    "Similarity threshold" = "{similarity}"
  ))
  cli::cli_rule()
  cli::cli_end()

  if (run_debug) {
    cli::cli_alert_info("Debug/dry-run mode is active. No actual HTTP requests will be made.")
  }

req_list <- map(query, ~{
  req <- request(burl) %>%
      req_url_path_append('similar-compound/by-dtxsid/') %>%
      req_url_path_append(.x) %>%
      req_url_path_append(similarity)
  
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
      } else {
      resp_body_json(.x) %>% 
        map(., as_tibble) %>% 
        list_rbind()
    }
    }) %>%
    list_rbind(names_to = 'query')

  return(results)
}

