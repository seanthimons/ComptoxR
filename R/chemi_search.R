#' Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search()
#' }
chemi_search <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "search",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


