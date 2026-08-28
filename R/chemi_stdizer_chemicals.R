#' Stdizer Chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param full Optional parameter
#' @param options Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_chemicals(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_stdizer_chemicals <- function(query, idType = "AnyId", full = NULL, options = NULL) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook("chemi_stdizer_chemicals", "pre_request", list(params = list(`query` = query, `idType` = idType, `full` = full, `options` = options, `chemicals` = chemicals, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("idType" %in% names(req_data$params)) {
    idType <- req_data$params[["idType"]]
  }
  if ("full" %in% names(req_data$params)) {
    full <- req_data$params[["full"]]
  }
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(full)) extra_options$full <- full
  if (!is.null(options)) extra_options$options <- options

  result <- generic_chemi_request(
    query = query,
    endpoint = "stdizer/chemicals",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
