#' Search
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Provides the ability to search against the Common Chemistry data source
#' Allows searching by CAS RN (with or without dashes), SMILES (canonical or isomeric), InChI (with or without the "InChI=" prefix), InChIKey, and name
#' Searching by name allows use of a trailing wildcard (e.g., car*)
#' All searches are case-insensitive
#' The result is in the form of substance summary information
#' The results are paginated, with a maximum page size of 100
#' 
#' @param q Required parameter
#' @param offset Optional parameter
#' @param size Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' cc_search(q = "123-91-1")
#' }
cc_search <- function(q, offset = NULL, size = NULL) {
  result <- generic_cc_request(
    endpoint = "search",
    method = "GET",
    `q` = q,
    `offset` = offset,
    `size` = size
  )

  # Additional post-processing can be added here

	if(result$count > 1){
		
		cli::cli_alert('Multiple results returned')

	}else{

		# Only one result

		result <- result %>% 
		pluck(., 'results', 1)

		if('images' %in% names(result)){
		result <- discard_at(result, 'images') %>% 
			as_tibble()
		}

	}

  return(result)
}


