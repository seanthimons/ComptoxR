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
	# 1. Input validation and setup ------
	query_vector <- unique(as.vector(query))
	request_method <- rlang::arg_match(request_method, values = c("GET", "POST"))

	# Informative CLI output -----
	cli::cli_rule(left = 'Synonym search options')
	cli::cli_dl(
		items = c(
			'Compound count' = "{length(query_vector)}",
			'Request method' = "{request_method}"
		)
	)
	cli::cli_end()
	cli::cat_line()

	# Build list of requests -----------------------------------------------------------------

	base_req <- httr2::request(Sys.getenv('burl')) %>%
		httr2::req_headers(
			accept = "application/json",
			`x-api-key` = ct_api_key()
		) %>%
		httr2::req_url_path("/chemical/synonym/search/by-dtxsid/")
	## GET requests ------

	if (request_method == "GET") {
		reqs <- purrr::map(
			stats::setNames(query_vector, query_vector),
			function(dtxsid) {
				base_req %>%
					httr2::req_method("GET") %>%
					httr2::req_url_path_append(dtxsid)
			}
		)
	}

	## POST requests ------

	if (request_method == "POST") {
		# Split queries into chunks of 100
		# ! NOTE: Documentation site usually says 200, other endpoints have been discovered to be ~100
		query_chunks <- split(
			query_vector,
			ceiling(seq_along(query_vector) / 100)
		)

		reqs <- purrr::map(query_chunks, function(chunk) {
			base_req %>%
				httr2::req_method("POST") %>%
				httr2::req_body_json(data = chunk, auto_unbox = TRUE)
		})
	}

	# Dry run ----

	if (isTRUE(as.logical(Sys.getenv('run_debug')))) {
		return(purrr::map(reqs, httr2::req_dry_run))
	}

	# Send requests ----
	resps <- httr2::req_perform_sequential(
		reqs,
		on_error = 'continue',
		progress = TRUE
	)

	# GET response parsing ----
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
				msg <- if (is.null(resp)) {
					"No response received from server."
				} else {
					as.character(resp)
				}
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
						purrr::map(
							.,
							~ {
								#inner list parsing
								purrr::map_if(.x, is.null, ~NA_character_)
							}
						) %>%
						compact() %>%
						map(., list_c) %>%
						map(., as_tibble) %>%
						list_rbind(names_to = 'quality')
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
					cli::cli_warn(
						"Query resulted in status 400 (Bad Request) with no parsable data. {msg}"
					)
					return(tibble::tibble()) # Return empty tibble if no data
				} else {
					cli::cli_warn(
						"Query resulted in status 400 (Bad Request). Body: {jsonlite::toJSON(body, auto_unbox = TRUE)}"
					)
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
				return(tibble::tibble(
					error = msg,
					message = paste("HTTP status", status)
				))
			}
		}) %>%
			purrr::list_rbind(names_to = "query")
	}

	# POST response parsing ----
	if (request_method == "POST") {
		# Process responses chunk by chunk, creating a list of tibbles
		results <- map2(resps, query_chunks, function(resp, chunk) {
			body <- httr2::resp_body_json(resp)

			body %>%
				set_names(chunk) %>% 
				map(., compact) %>%
				map(., ~ purrr::discard(.x, names(.) %in% c('pcCode', 'dtxsid'))) %>%
				map(., ~ map(., list_c)) %>%
				map(., ~ map(., as_tibble)) %>%
				map(., ~ list_rbind(.x, names_to = 'quality')) %>%
				list_rbind(., names_to = 'query')
		}) %>% list_rbind()
		return(results)
	}
}
