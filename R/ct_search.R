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

	# Check if query is a list (and not a dataframe) to flatten it
	if(is.list(query) && !is.data.frame(query)) {
    query <- as.character(unlist(query, use.names = FALSE))
  }
	
	# 1. Input validation and setup
	query_vector <- unique(as.vector(query))

	search_method <- rlang::arg_match(
		search_method,
		values = c('exact', 'starts', 'contains')
	)
	request_method <- rlang::arg_match(request_method, values = c('GET', 'POST'))

	# Informative CLI output
	cli::cli_rule(left = 'String search options')
	cli::cli_dl(
		items = c(
			'Compound count' = "{length(query_vector)}",
			'Request method' = "{request_method}",
			'Search type' = "{search_method}"
		)
	)
	cli::cli_end()
	cli::cat_line()

	# 2. Prepare requests

	# Determine API path from search method
	path <- switch(
		search_method,
		"exact" = "chemical/search/equal/",
		"starts" = "chemical/search/start-with/",
		"contains" = "chemical/search/contain/"
	)

	# Base request object
	base_req <- httr2::request(Sys.getenv('ctx_burl')) %>%
		httr2::req_headers(
			accept = "application/json",
			`x-api-key` = ct_api_key()
		) %>%
		httr2::req_url_path_append(path)

	# Prepare search values (handle CAS numbers, etc.)
	search_values_df <- tibble::enframe(
		query_vector,
		name = NULL,
		value = 'raw_search'
	) %>%
		dplyr::mutate(
			cas_chk = stringr::str_remove(.data$raw_search, "^0+"),
			cas_chk = stringr::str_remove_all(.data$cas_chk, "-"),
			# ! NOTE Swapped in native as_cas function
			cas_chk = as_cas(.data$cas_chk),
			searchValue = stringr::str_to_upper(.data$raw_search) %>%
				# ! NOTE Swaps out apostrophes to single quotes; seems to be best practice
				# ! TODO Perhaps expand the unicode list for other wild examples
				stringr::str_replace_all(., c('-' = ' ', '\\u00b4' = "'")),
			searchValue = dplyr::case_when(
				!is.na(.data$cas_chk) ~ .data$cas_chk,
				.default = .data$searchValue
			)
		) %>%
		dplyr::select("raw_search", "searchValue") %>%
		dplyr::filter(!is.na(.data$searchValue))

	if (Sys.getenv('run_debug')) {
		cli::cli_rule()
		cli::cli_alert_warning('Pre-flight cleaning of searched values:')
		print(head(search_values_df))
		cli::cli_rule()
		cli::cat_line()
	}

	# Build list of requests
	reqs <- list()

# GET request ------------------------------------------------------------

	if (request_method == 'GET') {
		# Create a named list of requests, one for each search value
		# Names are used later to map results back to the original query
		reqs <- purrr::map(
			stats::setNames(
				search_values_df$searchValue,
				search_values_df$raw_search
			),
			function(val) {
				req <- base_req %>%
					httr2::req_url_path_append(URLencode(val))

				if (search_method %in% c("starts", "contains")) {
					req <- req %>% httr2::req_url_query(top = '500')
				}
				req
			}
		)
	} 
	
# POST request -----------------------------------------------------------

		
	if (request_method == 'POST') {
		# For POST requests, split queries into chunks of 100 to avoid overly large requests.
		# Each chunk will be a separate POST request with a JSON body.
		search_chunks <- split(
			search_values_df,
			ceiling(seq_len(nrow(search_values_df)) / 100)
		)

		reqs <- purrr::map(search_chunks, function(chunk) {
			req <- base_req %>%
				# ! NOTE DOCUMENTATION FROM SITE: Search batch of values (values are separated by EOL character and maximum 200 values are allowed).
				# ! The body is a string, not an array!
				# The body is a JSON array of the search values for the current chunk.
				# The API expects a single string with values separated by newlines.
				httr2::req_body_raw(
					body = paste(chunk$searchValue, collapse = "\n"),
					type = "text/plain"
				)
		})
	}

	# 3. Execute requests and process responses

	if (isTRUE(as.logical(Sys.getenv('run_debug')))) {
		return(purrr::map(reqs, httr2::req_dry_run))
	}

	if (length(reqs) == 0) {
		cli::cli_alert_info("No valid queries to perform.")
		return(tibble::tibble())
	}

	resps <- httr2::req_perform_sequential(
		reqs,
		on_error = 'continue',
		progress = TRUE
	)

	# Parsing response -------------------------------------------------------

	## GET response -----------------------------------------------------------

	if (request_method == "GET") {
		# For GET, we have one response per query. We name them to map back.
		resps <- set_names(resps, names(reqs))

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
						purrr::compact() %>%
						purrr::map(~ purrr::map_if(.x, is.null, ~NA_character_)) %>%
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
					cli::cli_warn(
						"Query resulted in status 400 (Bad Request) with no parsable data. {msg}"
					)
					return(tibble::tibble()) # Return empty tibble if no data
				} else {
					# If body is valid and not empty, process it like a 2xx success.
					# No warning here, as it's treated as a successful data retrieval.
					return(
						body %>%
							purrr::compact() %>%
							purrr::map(~ purrr::map_if(.x, is.null, ~NA_character_)) %>%
							# ! NOTE Discards other list-elements aside from suggestions
							purrr::keep_at(., 'suggestions') %>%
							tibble::as_tibble() %>%
							tidyr::unnest_longer(., col = suggestions)
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
				return(tibble::tibble(
					error = msg,
					message = paste("HTTP status", status)
				))
			}
		}) %>%
			purrr::list_rbind(names_to = "raw_search")
	}

	## POST response ----------------------------------------------------------

	if (request_method == "POST") {
		# Re-create the chunks to map responses back to their original queries
		search_chunks <- split(
			search_values_df,
			ceiling(seq_len(nrow(search_values_df)) / 100)
		)

		# Process responses chunk by chunk, creating a list of tibbles
		results <- purrr::map2(resps, search_chunks, function(resp, chunk) {
			# This function processes ONE response from a POST chunk request
			# and returns a tibble of results for all queries in that chunk.

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
					raw_search = chunk$raw_search,
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
					raw_search = chunk$raw_search,
					error = msg,
					message = paste("HTTP status", status)
				))
			}

			# On success (2xx), parse the body.
			# The body is expected to be a list where each element contains the result(s)
			# for the corresponding query sent in the POST body.
			body <- httr2::resp_body_json(resp)
			if (length(body) == 0) {
				return(tibble::tibble()) # No results for this chunk
			}

			# The API should return one result list-element for each query sent.
			# If not, we cannot reliably map results back to queries.
			# if (length(body) != nrow(chunk)) {
			#   cli::cli_warn("POST response length ({length(body)}) does not match query chunk size ({nrow(chunk)}). Results for this chunk are being discarded.")
			#   return(tibble::tibble(raw_search = chunk$raw_search, error = "Response/Query mismatch", message = "Inconsistent number of results in response body."))
			# }

			# Name the list of results with the original `raw_search` values.
			# This assumes the API preserves the order of queries in its response.
			#names(body) <- chunk$raw_search

			# Process the named list of results into a single tibble for the chunk.
			body %>% # purrr::discard(is.null) # Discard queries that returned null; shouldn't be needed as the API returns for all.
				purrr::map(., function(result_for_one_query) {
					#   # This inner block processes the result for a single query, which might
					#   # itself be a list of multiple matches (e.g., for 'contains' search).
					#   if (length(result_for_one_query) == 0) return(NULL)

					result_for_one_query %>%
						purrr::map_if(., is.null, ~NA_character_) %>%
						tibble::as_tibble() %>%
						tidyr::unnest_longer(., col = suggestions) %>%
						select(-searchMsgs) %>%
						dplyr::mutate(
							dplyr::across(dplyr::where(is.numeric), as.character),
							dplyr::across(dplyr::where(is.logical), as.character)
						)
				},.progress = TRUE) %>% purrr::list_rbind()
		}) %>%
		# Row-bind the list of tibbles from each chunk into a single final tibble
		purrr::list_rbind()
	}
	return(results)
}