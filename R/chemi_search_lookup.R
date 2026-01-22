#' Search Lookup
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_lookup()
#' }
chemi_search_lookup <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "search/lookup",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


