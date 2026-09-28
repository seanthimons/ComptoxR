#' Returns information on a batch of methods using keyset pagination.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param cursor Optional keyset cursor returned by a previous response.
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_method_keyset_pagination(limit = "DTXSID7020182")
#' }
chemi_amos_method_keyset_pagination <- function(limit, cursor = NULL, all_pages = TRUE, max_pages = 100) {
  # Collect optional parameters
  options <- list()
  if (!is.null(cursor)) {
    options[['cursor']] <- cursor
  }
  result <- generic_request(
    query = limit,
    endpoint = "amos/method_keyset_pagination/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options,
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "cursor",
    pagination_cursor_location = "query"
  )

  # Additional post-processing can be added here

  return(result)
}
