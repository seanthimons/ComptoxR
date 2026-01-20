#' Returns substance(s) that match a search term.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_substances_for_term()
#' }
chemi_amos_get_substances_for_term <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_substances_for_search_term/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


