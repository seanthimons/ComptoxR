#' Search chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param page Optional parameter
#' @param size Optional parameter
#' @param query Optional parameter
#' @param lib_name Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database(page = "DTXSID7020182")
#' }
chemi_chet_chemicals_database <- function(page = 0, size = NULL, query = NULL, lib_name = NULL, all_pages = TRUE) {
  # Collect optional parameters
  options <- list()
  if (!is.null(page)) options[['page']] <- page
  if (!is.null(size)) options[['size']] <- size
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(lib_name)) options[['lib_name']] <- lib_name
    result <- generic_request(
    endpoint = "chemicals/database",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options,
    paginate = all_pages,
    max_pages = 100,
    pagination_strategy = "page_size"
  )

  # Additional post-processing can be added here

  return(result)
}


