# TODO Migrate to generic requests + promote to stable after testing

#' Product usage, functional usage, and exposure searching
#' 
#'
#' @details
#' For argument `domain` a list of parameters is offered:
#' \itemize{
#'  \item `func_use` Functional reported use
#'  \item `func_prob` Predicted function use
#' }
#'
#'
#' @param query A list of DTXSIDs
#' @param domain Search parameter to look for.
#'
#' @return Tibble or list of tibbles
#' @export

ct_functional_use <- function(
  query,
  domain = c('func_use', 'func_prob')
) {

	if(missing(domain)){domain <- c('func_use', 'func_prob')}

	if(length(domain) == 1){

		if(domain == 'func_use'){
			generic_request(
			query = query,
			endpoint = '/exposure/functional-use/search/by-dtxsid/',
			method = 'POST'
		)
		}else{
			generic_request(
			query = query,
			endpoint = 'exposure/functional-use/probability/search/by-dtxsid/',
			method = 'GET',
			batch_limit = 1
		)}

	}else{
		
		list(
			func_use = generic_request(
				query = query,
				endpoint = '/exposure/functional-use/search/by-dtxsid/',
				method = 'POST'),

			func_prob = generic_request(
				query = query,
				endpoint = 'exposure/functional-use/probability/search/by-dtxsid/',
				method = 'GET',
				batch_limit = 1)
		)
	}

}
