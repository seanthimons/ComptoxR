#' @param chems A character vector.
#' 
#' @returns An updated version of `ComptoxR::testing_chemicals`.

build_testing_chemicals <- function(chems = character(0)){
  
  if(length(chems) == 0){
    cli::cli_abort(c("No chemicals provided for integration."))
  }

  candidates <- ct_search(chems)
	
		failures <- candidates %>% 
		dplyr::select(dplyr::any_of(c("raw_search", "dtxsid")))
	
		if(identical(colnames(failures), c('raw_search', 'suggestions'))){

			cli::cli_alert_warning('No results found for:')
			failures %>% 
			pull(raw_search) %>% 
			cat()

		}else{
			
			cli::cli_alert_warning('No results found for:')
		
			failures %>% 
			filter(is.na(dtxsid)) %>% 
			pull(raw_search) %>% 
			cat()

		}
		
	new_chems <- candidates %>% 
		filter(dtxsid %ni% ComptoxR::testing_chemicals$dtxsid) %>% 	
		pull(dtxsid) %>% 
		ct_details(query = ., projection = 'id') %>%
		bind_rows(., ComptoxR::testing_chemicals) %>% 
		distinct() %>% 
		select(
			'preferredName',
			'casrn',
			'dtxsid',
			'dtxcid',
			'inchikey'
		)

	#return(new_chems)

	usethis::use_data(new_chems, overwrite = TRUE)
}

# build_testing_chemicals(c('Hexazine', 'testingdebug'))
