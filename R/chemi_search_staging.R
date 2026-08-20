#' Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param hazardNames Optional parameter
#' @param inputType Optional parameter. Options: UNKNOWN, AUTO, MOL, RXN, SDF, RDF, SMI, SMILES, SMIRKS, CSV, TSV, JSON, XLSX, TXT, MSP
#' @param limit Optional parameter
#' @param maxNumber Optional parameter
#' @param minNumber Optional parameter
#' @param offset Optional parameter
#' @param params Optional parameter
#' @param query Optional parameter
#' @param querySmiles Optional parameter
#' @param searchType Optional parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param smiles Optional parameter
#' @param sortBy Optional parameter
#' @param sortDirection Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_staging(hazardNames = "DTXSID1024122")
#' }
chemi_search_staging <- function(
  hazardNames = NULL,
  inputType = NULL,
  limit = NULL,
  maxNumber = NULL,
  minNumber = NULL,
  offset = 0,
  params = NULL,
  query = NULL,
  querySmiles = NULL,
  searchType = NULL,
  smiles = NULL,
  sortBy = NULL,
  sortDirection = NULL,
  all_pages = TRUE,
  max_pages = 100
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_search_staging",
    "pre_request",
    list(
      params = list(
        `hazardNames` = hazardNames,
        `inputType` = inputType,
        `limit` = limit,
        `maxNumber` = maxNumber,
        `minNumber` = minNumber,
        `offset` = offset,
        `params` = params,
        `query` = query,
        `querySmiles` = querySmiles,
        `searchType` = searchType,
        `smiles` = smiles,
        `sortBy` = sortBy,
        `sortDirection` = sortDirection,
        `all_pages` = all_pages,
        `max_pages` = max_pages,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("hazardNames" %in% names(req_data$params)) {
    hazardNames <- req_data$params[["hazardNames"]]
  }
  if ("inputType" %in% names(req_data$params)) {
    inputType <- req_data$params[["inputType"]]
  }
  if ("limit" %in% names(req_data$params)) {
    limit <- req_data$params[["limit"]]
  }
  if ("maxNumber" %in% names(req_data$params)) {
    maxNumber <- req_data$params[["maxNumber"]]
  }
  if ("minNumber" %in% names(req_data$params)) {
    minNumber <- req_data$params[["minNumber"]]
  }
  if ("offset" %in% names(req_data$params)) {
    offset <- req_data$params[["offset"]]
  }
  if ("params" %in% names(req_data$params)) {
    params <- req_data$params[["params"]]
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("querySmiles" %in% names(req_data$params)) {
    querySmiles <- req_data$params[["querySmiles"]]
  }
  if ("searchType" %in% names(req_data$params)) {
    searchType <- req_data$params[["searchType"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("sortBy" %in% names(req_data$params)) {
    sortBy <- req_data$params[["sortBy"]]
  }
  if ("sortDirection" %in% names(req_data$params)) {
    sortDirection <- req_data$params[["sortDirection"]]
  }
  if ("all_pages" %in% names(req_data$params)) {
    all_pages <- req_data$params[["all_pages"]]
  }
  if ("max_pages" %in% names(req_data$params)) {
    max_pages <- req_data$params[["max_pages"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(inputType)) {
    options$inputType <- inputType
  }
  if (!is.null(limit)) {
    options$limit <- limit
  }
  if (!is.null(maxNumber)) {
    options$maxNumber <- maxNumber
  }
  if (!is.null(minNumber)) {
    options$minNumber <- minNumber
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
    query = hazardNames,
    endpoint = "search",
    options = options,
    tidy = FALSE,
    server = server,
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "offset_limit"
  )

  # Additional post-processing can be added here

  return(result)
}
