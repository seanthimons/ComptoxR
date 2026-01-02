#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_exact(query = "DTXSID7020182")
#' }
chemi_search_exact <- function(query, exportSmiles = NULL, exportMol = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(exportSmiles)) options$exportSmiles <- exportSmiles
  if (!is.null(exportMol)) options$exportMol <- exportMol

  generic_chemi_request(
    query = query,
    endpoint = "api/search/exact",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}