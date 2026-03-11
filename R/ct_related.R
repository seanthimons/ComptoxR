# TODO Follow up to see if this will remain

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

# Experimental version using generic_request
# NOT exported - for validation only
ct_related_EXP <- function(query, inclusive = FALSE) {
  # Validation
  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector of DTXSIDs.")
  }

  if (inclusive == TRUE & length(query) == 1) {
    cli::cli_abort("Inclusive option only valid for multiple compounds")
  }

  # Display debugging information (preserve user experience)
  cli::cli_rule(left = "Related substances payload options")
  cli::cli_dl(
    c(
      "Number of compounds" = "{length(query)}",
      "Inclusive" = "{inclusive}"
    )
  )
  cli::cli_rule()
  cli::cli_end()

  # Server switch with guaranteed cleanup
  old_server <- Sys.getenv("ctx_burl")
  ctx_server(9)
  on.exit(Sys.setenv(ctx_burl = old_server), add = TRUE)

  # Manual loop over query items - generic_request doesn't support per-item
  # query parameters with batch_limit=1 (that appends to path, not query string)
  # So we use batch_limit=0 (static endpoint) and pass id as query parameter
  results <- purrr::map(
    query,
    function(dtxsid) {
      generic_request(
        query = NULL,
        endpoint = "related-substances/search/by-dtxsid",
        method = "GET",
        batch_limit = 0,
        auth = FALSE,
        tidy = FALSE,
        id = dtxsid  # Named parameter becomes query parameter
      )
    },
    .progress = TRUE
  ) %>%
    purrr::set_names(query)

  # Post-process: extract nested data, filter parent compound
  # This matches original behavior exactly
  data <- results %>%
    purrr::map(~ purrr::pluck(., "data")) %>%
    purrr::map(
      ~ purrr::map(
        .,
        ~ purrr::keep(.x, names(.x) %in% c("dtxsid", "relationship")) %>%
          tibble::as_tibble()
      ) %>%
        purrr::list_rbind()
    ) %>%
    purrr::list_rbind(names_to = "query") %>%
    dplyr::rename(child = dtxsid) %>%
    dplyr::filter(child != query)  # Remove parent compound

  # Apply inclusive filtering if requested
  if (inclusive == TRUE) {
    data <- dplyr::filter(data, query %in% query & child %in% query)
  }

  return(data)
}
