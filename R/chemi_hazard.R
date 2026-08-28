#' Hazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param full Optional parameter (default: TRUE)
#' @param format Output format. One of 'compact', 'tidy', or 'raw'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard(query = "DTXSID7020182")
#' }
chemi_hazard <- function(query, full = TRUE, format = c("compact", "tidy", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_hazard", "pre_request", list(params = list(`query` = query, `full` = full, `format` = format, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("full" %in% names(req_data$params)) {
    full <- req_data$params[["full"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(full)) options[['full']] <- full
    result <- generic_request(
    endpoint = "hazard",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

    result <- run_hook("chemi_hazard", "post_response", list(result = result, params = list(`query` = query, `full` = full, `format` = format)))
# Additional post-processing can be added here

  return(result)
}

#' Hazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param empty Optional parameter
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.options.analogsSearchType Optional parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, TOXPRINTS, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param request.options.cts Optional parameter
#' @param request.options.minSimilarity Optional parameter
#' @param request.options.noRecords Optional parameter
#' @param request.options.usePredictions Optional parameter
#' @param format Output format. One of 'compact', 'tidy', or 'raw'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_hazard_bulk <- function(query, idType = "AnyId", empty = NULL, options = NULL, request.filesInfo = NULL, request.options.analogsSearchType = NULL, request.options.cts = NULL, request.options.minSimilarity = NULL, request.options.noRecords = NULL, request.options.usePredictions = NULL, format = c("compact", "tidy", "raw")) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook("chemi_hazard_bulk", "pre_request", list(params = list(`query` = query, `idType` = idType, `empty` = empty, `options` = options, `request.filesInfo` = request.filesInfo, `request.options.analogsSearchType` = request.options.analogsSearchType, `request.options.cts` = request.options.cts, `request.options.minSimilarity` = request.options.minSimilarity, `request.options.noRecords` = request.options.noRecords, `request.options.usePredictions` = request.options.usePredictions, `format` = format, `chemicals` = chemicals, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("idType" %in% names(req_data$params)) {
    idType <- req_data$params[["idType"]]
  }
  if ("empty" %in% names(req_data$params)) {
    empty <- req_data$params[["empty"]]
  }
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("request.filesInfo" %in% names(req_data$params)) {
    request.filesInfo <- req_data$params[["request.filesInfo"]]
  }
  if ("request.options.analogsSearchType" %in% names(req_data$params)) {
    request.options.analogsSearchType <- req_data$params[["request.options.analogsSearchType"]]
  }
  if ("request.options.cts" %in% names(req_data$params)) {
    request.options.cts <- req_data$params[["request.options.cts"]]
  }
  if ("request.options.minSimilarity" %in% names(req_data$params)) {
    request.options.minSimilarity <- req_data$params[["request.options.minSimilarity"]]
  }
  if ("request.options.noRecords" %in% names(req_data$params)) {
    request.options.noRecords <- req_data$params[["request.options.noRecords"]]
  }
  if ("request.options.usePredictions" %in% names(req_data$params)) {
    request.options.usePredictions <- req_data$params[["request.options.usePredictions"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(empty)) extra_options$empty <- empty
  if (!is.null(options)) extra_options$options <- options

  result <- generic_chemi_request(
    query = query,
    endpoint = "hazard",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    request.filesInfo = request.filesInfo,
    request.options.analogsSearchType = request.options.analogsSearchType,
    request.options.cts = request.options.cts,
    request.options.minSimilarity = request.options.minSimilarity,
    request.options.noRecords = request.options.noRecords,
    request.options.usePredictions = request.options.usePredictions,
    server = server
  )

  result <- run_hook("chemi_hazard_bulk", "post_response", list(result = result, params = list(`query` = query, `idType` = idType, `empty` = empty, `options` = options, `request.filesInfo` = request.filesInfo, `request.options.analogsSearchType` = request.options.analogsSearchType, `request.options.cts` = request.options.cts, `request.options.minSimilarity` = request.options.minSimilarity, `request.options.noRecords` = request.options.noRecords, `request.options.usePredictions` = request.options.usePredictions, `format` = format)))
  # Additional post-processing can be added here

  return(result)
}
