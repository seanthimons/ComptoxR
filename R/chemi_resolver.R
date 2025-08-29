#' Resolve chemical identifiers using an external API

#'
#' This function takes a vector of chemical identifiers as input and uses an external API
#' to resolve them. It sends a POST request to the API endpoint, passing the identifiers
#' in the request body. The API response is then parsed to extract the 'chemical' field
#' from each returned object.
#'
#' @param query A character vector of chemical identifiers.
#' @param id_type A single string; one of `"DTXSID"`, `"DTXCID"`, `"SMILES"`,
#'   `"MOL"`, `"CAS"`, `"Name"`, `"InChI"`, `"InChIKey"`, `"InChIKey_1"`, or
#'   `"AnyId"`. Optional.
#' @param is_fuzzy A single logical value. Optional.
#' @param fuzzy_type A single string; one of `"Not"`, `"Anywhere"`, `"Start"`,
#'   `"Word"`, `"CloseSyntactic"`, or `"CloseSemantic"`. Required when
#'   `is_fuzzy` is `TRUE`.
#' @param mol A single logical value. If `TRUE`, returns a V3000 mol array.
#'   Optional.
#'
#' @return A list of resolved chemical information. Returns an empty list if no
#'   results are found. Errors if the API request fails.
#'
#' @export
chemi_resolver <- function(
	query,
	id_type = NULL,
	is_fuzzy = FALSE,
	fuzzy_type,
	mol = FALSE
) {
	# NOTE creates simple list if the length is 1, otherwise allows for boxed list

	query = as.list(query)

	init_query <- length(query)
	mult_count <- ceiling(length(query) / 200)
	mult_request <- mult_count > 1

	if (length(query) > 200) {
		query_list <- split(
			query,
			rep(1:mult_count, each = 200, length.out = length(query))
		)
	} else {
		query_list <- list(query)
	}

	# Check if the id_type argument is provided.
	# If not, stop execution and inform the user.
	if (missing(id_type) || is.null(id_type)) {
		cli::cli_alert_danger(
			'Missing ID type, defaulting to {cli::col_red("AnyID")}'
		)
		id_type <- 'AnyId'
	}

	# Validate the provided id_type against a predefined list of allowed values.
	# match.arg will throw an error if the user's input is not one of the choices.
	id_type <- rlang::arg_match(
		id_type,
		values = c(
			'DTXSID',
			'DTXCID',
			'SMILES',
			'MOL',
			'CAS',
			'Name',
			'InChI',
			'InChIKey',
			'InChIKey_1',
			'AnyId'
		)
	)

	# If fuzzy search is disabled, set the type to "Not". This ensures a
	# valid default is passed to arg_match, as fuzzy_type lacks a default.
	if (!is_fuzzy) {
		fuzzy_type <- "Not"
		# If fuzzy search is enabled, a `fuzzy_type` becomes mandatory.
	} else if (missing(fuzzy_type) || is.null(fuzzy_type)) {
		cli::cli_abort("When `is_fuzzy` is TRUE, a `fuzzy_type` must be provided.")
	}
	# Validate the provided fuzzy_type against a predefined list of allowed values.
	# match.arg will throw an error if the user's input is not one of the choices.
	fuzzy_type <- rlang::arg_match(
		fuzzy_type,
		values = c(
			"Not",
			"Anywhere",
			"Start",
			"Word",
			"CloseSyntactic",
			"CloseSemantic"
		)
	)

	# Returns the V3000 mol array
	# Checks for parameter validity
	if (!is.logical(mol) || missing(mol) || is.null(mol)) {
		if (as.logical(Sys.getenv('run_verbose'))) {
			cli::cli_alert_warning(
				'Mol parameter requires BOOLEAN value! Defaulting to {cli::col_red("FALSE")}.'
			)
		}
		mol <- FALSE
	} else {
		mol <- as.logical(mol)
	}

	req_list <- map(
		query_list,
		function(query_part) {
			request(Sys.getenv('chemi_burl')) %>%
			req_method("POST") %>%
			req_url_path_append("resolver/lookup") %>%
			req_headers(Accept = "application/json, text/plain, */*") %>%
			req_body_json(
				list(
					fuzzy = unbox(fuzzy_type),
					ids = query_part,
					idsType = unbox(id_type),
					mol = unbox(mol)
				)
			)
		}
	)

	if (as.logical(Sys.getenv('run_debug'))) {
		return(req_list %>% pluck(.,1) %>% req_dry_run())
	}

	if(mult_request){
		resp_list <- req_list %>%
		req_perform_sequential(., on_error = 'continue')
	}else{
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
		}) %>% list_c()

	cli_rule(left = 'Resolver results')
	cli_dl(
		c(
			'Number of compounds requested' = '{init_query}',
			'Number of batches' = '{mult_count}',
			'Number of compounds found' = '{length(body_list)}',
			'ID Type' = '{id_type}',
			'Fuzzy Search' = '{is_fuzzy}',
			'Fuzzy Type' = '{fuzzy_type}',
			'Mol' = '{mol}'
		)
	)
	cli::cli_rule()
	cli::cli_end()

	return(body_list)

	# map(body, ~ pluck(.x, 'chemical'))
}
