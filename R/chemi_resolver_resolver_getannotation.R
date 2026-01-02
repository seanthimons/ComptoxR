#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param heading Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolver_getannotation(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_getannotation <- function(query, heading = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(heading)) options$heading <- heading

  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/getannotation",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}