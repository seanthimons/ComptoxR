#' Search Lookup
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param searchType Required parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param inputType Optional parameter. Options: UNKNOWN, AUTO, MOL, RXN, SDF, RDF, SMI, SMILES, SMIRKS, CSV, TSV, JSON, XLSX, TXT, MSP
#' @param query Optional parameter
#' @param limit Optional parameter
#' @param params Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_lookup(searchType = "DTXSID7020182")
#' }
chemi_search_lookup <- function(searchType, inputType = NULL, query = NULL, limit = NULL, params = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(inputType)) options$inputType <- inputType
  if (!is.null(query)) options$query <- query
  if (!is.null(limit)) options$limit <- limit
  if (!is.null(params)) options$params <- params
  generic_chemi_request(
    query = searchType,
    endpoint = "search/lookup",
    options = options,
    tidy = FALSE
  )
}


