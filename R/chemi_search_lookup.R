#' Search Lookup
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param inputType Optional parameter. Options: UNKNOWN, AUTO, MOL, RXN, SDF, RDF, SMI, SMILES, SMIRKS, CSV, TSV, JSON, XLSX, TXT, MSP
#' @param limit Optional parameter
#' @param params Optional parameter
#' @param query Optional parameter
#' @param searchType Optional parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_lookup(inputType = "DTXSID1024122")
#' }
chemi_search_lookup <- function(inputType = NULL, limit = NULL, params = NULL, query = NULL, searchType = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(limit)) {
    options$limit <- limit
  }
  if (!is.null(params)) {
    options$params <- params
  }
  if (!is.null(query)) {
    options$query <- query
  }
  if (!is.null(searchType)) {
    options$searchType <- searchType
  }
  result <- generic_chemi_request(
    query = inputType,
    endpoint = "search/lookup",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
