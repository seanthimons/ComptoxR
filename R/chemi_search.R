#' Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param inputType Optional parameter. Options: UNKNOWN, AUTO, MOL, RXN, SDF, RDF, SMI, SMILES, SMIRKS, CSV, TSV, JSON, XLSX, TXT, MSP
#' @param limit Optional parameter
#' @param offset Optional parameter
#' @param params Optional parameter
#' @param query Optional parameter
#' @param querySmiles Optional parameter
#' @param searchType Optional parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param smiles Optional parameter
#' @param sortBy Optional parameter
#' @param sortDirection Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search(inputType = "DTXSID1024122")
#' }
chemi_search <- function(
  inputType = NULL,
  limit = NULL,
  offset = 0,
  params = NULL,
  query = NULL,
  querySmiles = NULL,
  searchType = NULL,
  smiles = NULL,
  sortBy = NULL,
  sortDirection = NULL,
  all_pages = TRUE
) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(limit)) {
    options$limit <- limit
  }
  if (!is.null(offset)) {
    options$offset <- offset
  }
  if (!is.null(params)) {
    options$params <- params
  }
  if (!is.null(query)) {
    options$query <- query
  }
  if (!is.null(querySmiles)) {
    options$querySmiles <- querySmiles
  }
  if (!is.null(searchType)) {
    options$searchType <- searchType
  }
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  if (!is.null(sortBy)) {
    options$sortBy <- sortBy
  }
  if (!is.null(sortDirection)) {
    options$sortDirection <- sortDirection
  }
  result <- generic_chemi_request(
    query = inputType,
    endpoint = "search",
    options = options,
    tidy = FALSE,
    paginate = all_pages,
    max_pages = 100,
    pagination_strategy = "offset_limit"
  )

  # Additional post-processing can be added here

  return(result)
}
