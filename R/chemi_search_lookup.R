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
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_search_lookup",
    "pre_request",
    list(
      params = list(
        `inputType` = inputType,
        `limit` = limit,
        `params` = params,
        `query` = query,
        `searchType` = searchType,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("inputType" %in% names(req_data$params)) {
    inputType <- req_data$params[["inputType"]]
  }
  if ("limit" %in% names(req_data$params)) {
    limit <- req_data$params[["limit"]]
  }
  if ("params" %in% names(req_data$params)) {
    params <- req_data$params[["params"]]
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("searchType" %in% names(req_data$params)) {
    searchType <- req_data$params[["searchType"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
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
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
