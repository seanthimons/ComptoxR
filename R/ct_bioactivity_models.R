#' Return ToxCast models for given dtxsid
#' 
#' @param query List of DTXSIDs to search for
#' 
#' @returns A tibble
#' @export

ct_bioactivity_models <- function(query) {
	if (!is.character(query) || length(query) == 0) {
		cli_abort("{.arg query} must be a non-empty character vector of DTXSIDs.")
	}

	cli::cli_rule(left = "ToxCast Bioactivity options")
	cli::cli_dl(c("Number of compounds" = "{length(query)}"))
	cli::cli_rule()
	cli::cli_end()

	req_list <- query %>%
		map(., function(dtxsid) {
			httr2::request(Sys.getenv('burl')) %>%
				httr2::req_headers(
					accept = "application/json",
					`x-api-key` = ct_api_key()
				) %>%
				httr2::req_url_path_append(
					"bioactivity/models/search/by-dtxsid",
					dtxsid
				)
		})

	if (as.logical(Sys.getenv("run_debug", "FALSE"))) {
		cli_alert_info(
			"Debug mode is ON. Performing a dry run for the first query item."
		)
		return(req_list[[1]] %>% req_dry_run())
	}

	resp_list <- req_list %>%
		req_perform_sequential(on_error = 'continue', progress = TRUE) %>%
		set_names(query)

	result <- resp_list %>%
		resps_successes() %>%
		map(
			.,
			~ resp_body_json(.x) %>%
				map(., ~ tibble::as_tibble(.x)) %>%
				list_rbind()
		) %>%
		compact() %>%
		list_rbind(names_to = 'dtxsid')

	if ('modelDesc' %in% colnames(result)) {
		result <- result %>%
			select(-modelDesc, -id)
	}

	return(result)
}