#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter
#' @param min Optional parameter
#' @param max Optional parameter
#' @param similarityType Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_similar(query = "DTXSID7020182")
#' }
chemi_search_similar <- function(query, exportSmiles = NULL, exportMol = NULL, min = NULL, max = NULL, similarityType = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(exportSmiles)) options$exportSmiles <- exportSmiles
  if (!is.null(exportMol)) options$exportMol <- exportMol
  if (!is.null(min)) options$min <- min
  if (!is.null(max)) options$max <- max
  if (!is.null(similarityType)) options$similarityType <- similarityType

  generic_chemi_request(
    query = query,
    endpoint = "api/search/similar",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}