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
#' @return A `tibble` containing the aggregated functional use data


chemi_functional_use <- function(query) {

  if (!is.character(query) || length(query) == 0) {
    cli_abort("{.arg query} must be a non-empty character vector of DTXSIDs.")
  }

  cli::cli_rule(left = "Functional Use options")
  cli::cli_dl(c("Number of compounds" = "{length(query)}"))
  cli::cli_rule()
	cli::cli_end()

	req_list <- query %>% 
		map(., function(dtxsid) {
			request(Sys.getenv('chemi_burl')) %>%
			req_url_path_append("amos/functional_uses_for_dtxsid", dtxsid)})

  if (as.logical(Sys.getenv("run_debug", "FALSE"))) {
    cli_alert_info("Debug mode is ON. Performing a dry run for the first query item.")
		return(req_list[[1]] %>% req_dry_run())
  }

	resp_list <- req_list %>% 
		req_perform_sequential(on_error = 'continue', progress = TRUE) %>% 
		set_names(query)

	# TODO the map is not quite perfect. 
	result <- resp_list %>% 
		resps_successes() %>% 
    map(.,
			~ resp_body_json(.x) %>% as_tibble() %>% unnest('functional_classes')
			) %>%
		list_rbind(names_to = 'dtxsid')


	return(result)  
}

