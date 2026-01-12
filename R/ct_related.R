# R/ct_related.R

#' Get related substances from the EPA CompTox dashboard.
#'
#' @description
#' `r lifecycle::badge("questioning")`
#'
#' @param query A character vector of DTXSIDs to query.
#' @param inclusive Boolean to only return results within all of the queried compounds. Valid for over one compound.
#' @export
#' 
#' @return A list of data frames containing related substances.
#' @export
#'
#' @examples
#' \dontrun{
#' ct_related(query = "DTXSID0024842")
#' }
#'

ct_related <- function(query, inclusive = FALSE) {
  # Check if query is valid
  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector of DTXSIDs.")
  }

	# Check if query is valid for inclusion

	if (inclusive == TRUE & length(query) == 1) {
		cli::cli_abort("Inclusive option only valid for multiple compounds")
	}

  # Display debugging information
  cli::cli_rule(left = "Related substances payload options")
  cli::cli_dl(
		c(
			"Number of compounds" = "{length(query)}",
			"Inclusive" = "{inclusive}"
		)
	)
  cli::cli_rule()
  cli::cli_end()
  #TODO Remove after API endpoint comes up
  ctx_server(server = 9)

  # Helper function to fetch data safely
  safe_fetch <- purrr::safely(function(id) {
    #cli::cli_inform(c("v" = "Fetching related substances for DTXSID: {id}"))

    # Make the request
    req <- request(base_url = Sys.getenv('ctx_burl')) %>%
      req_url_path_append('related-substances/search/by-dtxsid') %>%
      req_url_query('id' = id)

    # Dry run option
    if (Sys.getenv("run_debug") == "TRUE") {
      cli::cli_alert_info('DEBUGGING REQUEST')

      print(req)
      #return(NULL)
    }

    resp <- httr2::req_perform(req)

    # Check the response
    if (httr2::resp_status(resp) != 200) {
      cli::cli_warn(
        "Request failed for DTXSID: {id} with status {httr2::resp_status(resp)}"
      )
      return(NULL)
    }

    # Parse the JSON content
    httr2::resp_body_json(resp)
  })

  # Fetch data for all IDs sequentially with a progress bar
  results <- query %>%
    purrr::map(safe_fetch, .progress = TRUE) %>%
    set_names(query)

  # Extract the results and errors
  data <- purrr::map(results, "result") %>%
    map(., ~ pluck(., "data")) %>%
    map(
      .,
      ~ map(
        .,
        ~ keep(.x, names(.x) %in% c("dtxsid", "relationship")) %>% as_tibble()
      ) %>%
        list_rbind()
    ) %>%
    list_rbind(names_to = "query") %>%
		rename(child = dtxsid) %>% 
		#Removes parent searched compound
    filter(child != query)
  
  errors <- purrr::map(results, "error")

  # Handle errors
  if (any(!purrr::map_lgl(errors, is.null))) {
    cli::cli_warn(c(
      "x" = "Some requests failed:",
      "i" = "{sum(!purrr::map_lgl(errors, is.null))} DTXSIDs had errors."
    ))
  }
  ctx_server(server = 1)

if(inclusive == TRUE){

data <- data %>% 
	filter(query %in% query & child %in% query)
}	

  # Return the data
  return(data)
}
