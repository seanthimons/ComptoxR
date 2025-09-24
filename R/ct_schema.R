#' Download API schemas
#'
#' @description
#' This function downloads the JSON schemas for the various ComptoxAI API 
#' endpoints (chemical, hazard, bioactivity, exposure) and for each server 
#' environment (production, staging, development). The schemas are saved in the 
#' 'schema' directory of the project.
#'
#' @return Invisibly sets the server to production and returns `NULL`.
#'
#' @examples
#' if (interactive()) {
#'  ct_schema()
#' }
ct_schema <- function(){

	serv = list(
		'prod' = 1,
		'staging' = 2, 
		'dev' = 3
	)

	ct_endpoints <- c(
		'chemical'
		,'hazard'
		,'bioactivity'
		,'exposure'
	)

	map(ct_endpoints, function(endpoint){

		imap(serv, function(idx, server){

			# Sets the path
				ct_server(idx)

				download.file(
				url = paste0(Sys.getenv('burl'), 'docs/', endpoint, '.json'), 
				destfile = here::here('schema', paste0(endpoint,'_',server,'.json'))
				)
			
			})
		}, .progress = TRUE)
	
	invisible(ct_server(1))
}
