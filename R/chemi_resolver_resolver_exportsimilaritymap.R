#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param format Optional parameter
#' @param sort Optional parameter
#' @param showImage Optional parameter
#' @param limit Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolver_exportsimilaritymap(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_exportsimilaritymap <- function(query, format = NULL, sort = NULL, showImage = NULL, limit = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(format)) options$format <- format
  if (!is.null(sort)) options$sort <- sort
  if (!is.null(showImage)) options$showImage <- showImage
  if (!is.null(limit)) options$limit <- limit

  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/exportsimilaritymap",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}