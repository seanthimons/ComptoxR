#' Resolve chemical identifiers using an external API.

#'
#' This function takes a vector of chemical identifiers as input and uses an external API
#' to resolve them. It sends a POST request to the API endpoint, passing the identifiers
#' in the request body. The API response is then parsed to extract the 'chemical' field
#' from each returned object.
#'
#' @param query A character vector of chemical identifiers to resolve.
#' @param mol Boolean to return mol section.
#' @return A list containing the resolved chemical names. Each element of the list
#'   corresponds to an identifier in the input `query`.  Returns an empty list if the
#'   API returns no results for a given query.
#'
#' @export
chemi_resolver <- function(query, id_type = NULL, is_fuzzy = FALSE, fuzzy_type, mol = FALSE) {

	# NOTE creates simple list if the length is 1, otherwise allows for boxed list
	if(length(query) == 1){
		query <- list(query)
	}

	if(missing(id_type) || is.null(id_type)){
		cli::cli_abort('Missing ID type!')
	}

	id_type <- match.arg(id_type, choices = c('DTXSID', 'DTXCID', 'SMILES', 'MOL', 'CAS', 'Name', 'InChI', 'InChIKey', 'InChIKey_1', 'AnyId'))

	if(is_fuzzy & (missing(fuzzy_type) || is.null(fuzzy_type))){
		cli::cli_abort('Missing Fuzzy search type!')
	}

	

  req <- request(Sys.getenv('chemi_burl')) %>%
    req_method("POST") %>%
    req_url_path_append("resolver/lookup") %>%
    req_headers(Accept = "application/json, text/plain, */*") %>%
    req_body_json(
      list(
        fuzzy = fuzzy_type,
        ids = query,
        idsType = id_type,
        mol = mol
      ),
      auto_unbox = TRUE
    )

	if(as.logical(Sys.getenv('run_debug'))){

		return(req %>% req_dry_run())
		
	}
	
  resp <- req %>%
    req_perform()

  if (resp_status(resp) < 200 || resp_status(resp) >= 300) {
    cli::cli_abort(paste("API request failed with status", resp_status(resp)))
  }

  body <- resp_body_json(resp)

  if (length(body) == 0) {
    cli::cli_alert_warning("No results found for the given query.")
    return(list())
  }

  cli_rule(left = 'Resolver results')
  cli_dl(
    c(
      'Number of compounds requested' = '{length(query)}',
      'Number of compounds found' = '{length(body)}',
			'ID Type' = '{id_type}'
    )
  )
  cli::cli_rule()
  cli::cli_end()

  map(body, ~ pluck(.x, 'chemical'))
}
