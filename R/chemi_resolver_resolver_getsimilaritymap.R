#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param sort Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolver_getsimilaritymap(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_getsimilaritymap <- function(query, sort = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(sort)) options$sort <- sort

  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/getsimilaritymap",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}