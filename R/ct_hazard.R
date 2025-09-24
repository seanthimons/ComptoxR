#'Retrieves for hazard data by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_hazard <- function(query, request_method = "GET", ...) {

	query_vector <- unique(as.vector(query))

	request_method <- rlang::arg_match(request_method, values = c('GET', 'POST'))

  cli::cli_rule(left = 'Hazard payload options')
  cli::cli_dl(
    c(
      'Number of compounds: ' = '{length(query_vector)}',
			'Request method: ' = '{request_method}'
    )
  )

	# Base request object
	base_req <- httr2::request(Sys.getenv('burl')) %>%
		httr2::req_headers(
			accept = "application/json",
			`x-api-key` = ct_api_key()
		) %>%
		httr2::req_url_path_append("hazard/toxval/search/by-dtxsid/")

# GET request ------------------------------------------------------------

	if (request_method == 'GET') {
		# Create a named list of requests, one for each search value
		# Names are used later to map results back to the original query
		reqs <- purrr::map(
			stats::setNames(
				query_vector,
				query_vector
			),
			function(val) {
				req <- base_req %>%
					httr2::req_url_path_append(URLencode(val))
			}
		)
	} 
	
# POST request -----------------------------------------------------------

	if (request_method == 'POST') {
		# For POST requests, split queries into chunks of 100 to avoid overly large requests.
		# Each chunk will be a separate POST request with a JSON body.
		search_chunks <- split(
			query_vector,
			ceiling(seq_len(nrow(query_vector)) / 200)
		)

		reqs <- purrr::map(search_chunks, function(chunk) {
			req <- base_req %>%
				# ! NOTE DOCUMENTATION FROM SITE: Maximum 200 DTXSIDs per request
				# The body is a JSON array of the search values for the current chunk.
				httr2::req_body_json(
					body = list(chunk),
					type = "text/plain"
				)
		})
	}

	# 3. Execute requests and process responses

	if (isTRUE(as.logical(Sys.getenv('run_debug')))) {
		return(purrr::map(reqs[1], httr2::req_dry_run))
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
