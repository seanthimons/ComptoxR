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
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_alerts <- function(query, idType = "AnyId", options = NULL) {
  chemicals <- NULL
  req_data <- run_hook(
    "chemi_alerts",
    "pre_request",
    list(params = list(query = query, idType = idType, options = options, chemicals = chemicals))
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
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(options)) {
    extra_options$options <- options
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "alerts",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
