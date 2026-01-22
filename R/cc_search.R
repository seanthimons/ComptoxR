#' Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param q Required parameter
#' @param offset Optional parameter
#' @param size Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' cc_search(q = "123-91-1")
#' }
cc_search <- function(q, offset = NULL, size = NULL) {
  result <- generic_cc_request(
    endpoint = "search",
    method = "GET",
    q = q,
    offset = offset,
    size = size
  )

  # Additional post-processing can be added here

  return(result)
}


