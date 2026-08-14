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
#' @param request.options.authority Optional parameter
#' @param request.options.cts Optional parameter
#' @param request.options.fingerprintType Optional parameter
#' @param request.options.hazardName Optional parameter
#' @param request.options.maxNumber Optional parameter
#' @param request.options.minNumber Optional parameter
#' @param request.options.minSimilarity Optional parameter
#' @param request.options.noRecords Optional parameter
#' @param request.options.similarityType Optional parameter
#' @param request.options.usePredictions Optional parameter
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard_bulk_staging(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_hazard_bulk_staging <- function(
  query,
  idType = "AnyId",
  empty = NULL,
  options = NULL,
  request.filesInfo = NULL,
  request.options.analogsSearchType = NULL,
  request.options.authority = NULL,
  request.options.cts = NULL,
  request.options.fingerprintType = NULL,
  request.options.hazardName = NULL,
  request.options.maxNumber = NULL,
  request.options.minNumber = NULL,
  request.options.minSimilarity = NULL,
  request.options.noRecords = NULL,
  request.options.similarityType = NULL,
  request.options.usePredictions = NULL
) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_hazard_bulk_staging",
    "pre_request",
    list(
      params = list(
        `query` = query,
        `idType` = idType,
        `empty` = empty,
        `options` = options,
        `request.filesInfo` = request.filesInfo,
        `request.options.analogsSearchType` = request.options.analogsSearchType,
        `request.options.authority` = request.options.authority,
        `request.options.cts` = request.options.cts,
        `request.options.fingerprintType` = request.options.fingerprintType,
        `request.options.hazardName` = request.options.hazardName,
        `request.options.maxNumber` = request.options.maxNumber,
        `request.options.minNumber` = request.options.minNumber,
        `request.options.minSimilarity` = request.options.minSimilarity,
        `request.options.noRecords` = request.options.noRecords,
        `request.options.similarityType` = request.options.similarityType,
        `request.options.usePredictions` = request.options.usePredictions,
        `chemicals` = chemicals,
        `server` = server
      )
    )
  )
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
  if ("request.options.authority" %in% names(req_data$params)) {
    request.options.authority <- req_data$params[["request.options.authority"]]
  }
  if ("request.options.cts" %in% names(req_data$params)) {
    request.options.cts <- req_data$params[["request.options.cts"]]
  }
  if ("request.options.fingerprintType" %in% names(req_data$params)) {
    request.options.fingerprintType <- req_data$params[["request.options.fingerprintType"]]
  }
  if ("request.options.hazardName" %in% names(req_data$params)) {
    request.options.hazardName <- req_data$params[["request.options.hazardName"]]
  }
  if ("request.options.maxNumber" %in% names(req_data$params)) {
    request.options.maxNumber <- req_data$params[["request.options.maxNumber"]]
  }
  if ("request.options.minNumber" %in% names(req_data$params)) {
    request.options.minNumber <- req_data$params[["request.options.minNumber"]]
  }
  if ("request.options.minSimilarity" %in% names(req_data$params)) {
    request.options.minSimilarity <- req_data$params[["request.options.minSimilarity"]]
  }
  if ("request.options.noRecords" %in% names(req_data$params)) {
    request.options.noRecords <- req_data$params[["request.options.noRecords"]]
  }
  if ("request.options.similarityType" %in% names(req_data$params)) {
    request.options.similarityType <- req_data$params[["request.options.similarityType"]]
  }
  if ("request.options.usePredictions" %in% names(req_data$params)) {
    request.options.usePredictions <- req_data$params[["request.options.usePredictions"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(empty)) {
    extra_options$empty <- empty
  }
  if (!is.null(options)) {
    extra_options$options <- options
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "hazard",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    request.filesInfo = request.filesInfo,
    request.options.analogsSearchType = request.options.analogsSearchType,
    request.options.authority = request.options.authority,
    request.options.cts = request.options.cts,
    request.options.fingerprintType = request.options.fingerprintType,
    request.options.hazardName = request.options.hazardName,
    request.options.maxNumber = request.options.maxNumber,
    request.options.minNumber = request.options.minNumber,
    request.options.minSimilarity = request.options.minSimilarity,
    request.options.noRecords = request.options.noRecords,
    request.options.similarityType = request.options.similarityType,
    request.options.usePredictions = request.options.usePredictions,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
