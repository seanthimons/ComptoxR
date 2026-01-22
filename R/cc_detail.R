#' Detail
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Provides the ability to get substance details for a single substance at a time
#'
#' @param cas_rn Required parameter
#' @param uri Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' cc_detail(cas_rn = "123-91-1")
#' }
cc_detail <- function(cas_rn, uri = NULL) {
  result <- generic_cc_request(
    endpoint = "detail",
    method = "GET",
    `cas_rn` = cas_rn,
    `uri` = uri
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


