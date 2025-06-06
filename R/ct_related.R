# R/ct_related.R

#' Get related substances from the EPA CompTox dashboard.

#'
#' @param query A character vector of DTXSIDs to query.
#'
#' @return A list of data frames containing related substances.
#' @export
#'
#' @examples
#' \dontrun{
#' get_related_substances(query = "DTXSID0024842")
#' }
#' `r lifecycle::badge("experimental")`

ct_related <- function(query) {
  # Check if query is valid
  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector of DTXSIDs.")
  }

  # Display debugging information
  cli::cli_rule(left = "Related substances payload options")
  cli::cli_dl(c("Number of compounds" = "{length(query)}"))
  cli::cli_rule()
  cli::cli_end()

  #TODO Remove after API endpoint comes up
  ct_server(server = 3)

  # Helper function to fetch data safely
  safe_fetch <- purrr::safely(function(id) {
    cli::cli_inform(c("v" = "Fetching related substances for DTXSID: {id}"))

    # Make the request
    req <- httr2::request(
      Sys.getenv('ct_burl')
    ) %>%
      req_url_path_append('related-substances/search/by-dtxsid') %>%
      req_url_query('id' = id)
    
    # Dry run option
    if (Sys.getenv("run_debug") == "TRUE") {
      print(req)
      return(NULL)
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
    purrr::map(safe_fetch)

  # Extract the results and errors
  data <- purrr::map(results, "result")
  errors <- purrr::map(results, "error")

  # Handle errors
  if (any(!purrr::map_lgl(errors, is.null))) {
    cli::cli_warn(c(
      "x" = "Some requests failed:",
      "i" = "{sum(!purrr::map_lgl(errors, is.null))} DTXSIDs had errors."
    ))
  }
  ct_server(server = 1)
  # Return the data
  return(data)
}
