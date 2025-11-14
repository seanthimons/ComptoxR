#' Retrieves Chemical Fate and Transport parameters
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#'
#' @return Returns a tibble with results
#' @export

ct_env_fate <- function(query) {
	if (length(query) == 0) {
		cli::cli_abort("Query must be a character vector of DTXSIDs.")
	}

	init_query <- length(query)
	batch_limit <- as.numeric(Sys.getenv("batch_limit"))
	mult_count <- ceiling(length(query) / batch_limit)
	mult_request <- mult_count > 1

	if (length(query) > batch_limit) {
		query_list <- split(
			query,
			rep(1:mult_count, each = batch_limit, length.out = length(query))
		)
	} else {
		query_list <- list(query)
	}

	run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
	run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

	if (run_verbose) {
		cli_rule(left = 'Fate and transport payload options')
		cli_dl(
			c(
				'Number of compounds' = '{length(query)}',
				'Number of batches' = '{mult_count}'
			)
		)
		cli::cli_rule()
		cli::cli_end()
	}

	req_list <- map(
		query_list,
		function(query_part) {
			request(Sys.getenv('burl')) %>%
				req_method("POST") %>%
				req_url_path_append("chemical/fate/search/by-dtxsid/") %>%
				req_headers(
					Accept = "application/json",
					`x-api-key` = ct_api_key()
				) %>%
				req_body_json(
					query_part
				)
		}
	)

	if (as.logical(Sys.getenv('run_debug'))) {
		return(req_list %>% pluck(., 1) %>% req_dry_run())
	}

	if (mult_request) {
		resp_list <- req_list %>%
			req_perform_sequential(., on_error = 'continue')
	} else {
		resp_list <- list(req_perform(req_list[[1]]))
	}

	body_list <- resp_list %>%
		map(., function(r) {
			if (resp_status(r) < 200 || resp_status(r) >= 300) {
				cli::cli_abort(paste(
					"API request failed with status",
					resp_status(r)
				))
			}

			body <- resp_body_json(r)

			if (length(body) == 0) {
				cli::cli_alert_warning("No results found for the given query.")
				return(list())
			}
			return(body)
		}) %>%
		list_c()

	return(
		body_list %>% 
			map(., ~ 
				
				as_tibble(.x)
			) %>%
			list_rbind()
	)
	
	
}
