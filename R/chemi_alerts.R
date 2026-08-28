#' Alerts
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.options.alerts Optional parameter
#' @param request.options.resolve Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_alerts <- function(query, idType = "AnyId", options = NULL, request.filesInfo = NULL, request.options.alerts = NULL, request.options.resolve = NULL) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook("chemi_alerts", "pre_request", list(params = list(`query` = query, `idType` = idType, `options` = options, `request.filesInfo` = request.filesInfo, `request.options.alerts` = request.options.alerts, `request.options.resolve` = request.options.resolve, `chemicals` = chemicals, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("idType" %in% names(req_data$params)) {
    idType <- req_data$params[["idType"]]
  }
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("request.filesInfo" %in% names(req_data$params)) {
    request.filesInfo <- req_data$params[["request.filesInfo"]]
  }
  if ("request.options.alerts" %in% names(req_data$params)) {
    request.options.alerts <- req_data$params[["request.options.alerts"]]
  }
  if ("request.options.resolve" %in% names(req_data$params)) {
    request.options.resolve <- req_data$params[["request.options.resolve"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(options)) extra_options$options <- options

  result <- generic_chemi_request(
    query = query,
    endpoint = "alerts",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    request.filesInfo = request.filesInfo,
    request.options.alerts = request.options.alerts,
    request.options.resolve = request.options.resolve,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
