#' Search chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param page Optional parameter
#' @param size Optional parameter
#' @param query Optional parameter
#' @param exact_search Optional parameter
#' @param lib_name Optional parameter
#' @param only_in_reactions Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database(page = "DTXSID7020182")
#' }
chemi_chet_chemicals_database <- function(
  page = 0,
  size = NULL,
  query = NULL,
  exact_search = NULL,
  lib_name = NULL,
  only_in_reactions = NULL,
  all_pages = TRUE
) {
  # Collect optional parameters
  options <- list()
  if (!is.null(page)) {
    options[['page']] <- page
  }
  if (!is.null(size)) {
    options[['size']] <- size
  }
  if (!is.null(query)) {
    options[['query']] <- query
  }
  if (!is.null(exact_search)) {
    options[['exact_search']] <- exact_search
  }
  if (!is.null(lib_name)) {
    options[['lib_name']] <- lib_name
  }
  if (!is.null(only_in_reactions)) {
    options[['only_in_reactions']] <- only_in_reactions
  }
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
