#' Returns all public lists that contain a queried compound
#'
#' @param query A DTXSID to search by.
#'
#' @return Returns a named list with results
#' @export

ct_compound_in_list <- function(query) {

  # Use generic_request with tidy=FALSE to get list output
  results <- generic_request(
    query = query,
    endpoint = "chemical/list/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    tidy = FALSE,
    projection = 'chemicallistname'
  )

  # Extract the first element from each result (list of list names)
  df <- results %>%
    purrr::map(~ {
      if (is.list(.x) && length(.x) > 0) {
        list_names <- purrr::pluck(.x, 1)
        cli::cli_alert_success('{length(list_names)} lists found!')
        return(list_names)
      } else {
        cli::cli_alert_warning('No lists found')
        return(NULL)
      }
    }) %>%
    purrr::set_names(query) %>%
    purrr::compact()

  return(df)
}
