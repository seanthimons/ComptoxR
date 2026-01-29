#' Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param searchType Optional parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param inputType Optional parameter. Options: UNKNOWN, AUTO, MOL, RXN, SDF, RDF, SMI, SMILES, SMIRKS, CSV, TSV, JSON, XLSX, TXT, MSP
#' @param query Optional parameter
#' @param smiles Optional parameter
#' @param querySmiles Optional parameter
#' @param offset Optional parameter
#' @param limit Optional parameter
#' @param sortBy Optional parameter
#' @param sortDirection Optional parameter
#' @param params Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search(searchType = c("DTXSID10894891", "DTXSID2024030", "DTXSID701018815"))
#' }
chemi_search <- function(searchType = NULL, inputType = NULL, query = NULL, smiles = NULL, querySmiles = NULL, offset = NULL, limit = NULL, sortBy = NULL, sortDirection = NULL, params = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(inputType)) options$inputType <- inputType
  if (!is.null(query)) options$query <- query
  if (!is.null(smiles)) options$smiles <- smiles
  if (!is.null(querySmiles)) options$querySmiles <- querySmiles
  if (!is.null(offset)) options$offset <- offset
  if (!is.null(limit)) options$limit <- limit
  if (!is.null(sortBy)) options$sortBy <- sortBy
  if (!is.null(sortDirection)) options$sortDirection <- sortDirection
  if (!is.null(params)) options$params <- params
  result <- generic_chemi_request(
    query = searchType,
    endpoint = "search",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


