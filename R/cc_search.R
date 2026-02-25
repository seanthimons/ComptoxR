#' Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param q Optional parameter
#' @param offset Optional parameter
#' @param size Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' cc_search(q = "123-91-1")
#' }
cc_search <- function(q = NULL, offset = 0, size = NULL, all_pages = TRUE) {
  result <- generic_cc_request(
    endpoint = "search",
    method = "GET",
    `q` = q,
    `offset` = offset,
    `size` = size,
    paginate = all_pages,
    max_pages = 100,
    pagination_strategy = "offset_limit"
  )

  # Additional post-processing can be added here

  return(result)
}


