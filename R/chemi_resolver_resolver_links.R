#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param idType Optional parameter
#' @param fuzzy Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolver_links(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_links <- function(query, idType = NULL, fuzzy = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(idType)) options$idType <- idType
  if (!is.null(fuzzy)) options$fuzzy <- fuzzy

  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/links",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}