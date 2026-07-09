#' Resolver Universalharvest Cart
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param info Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_universalharvest_cart(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_universalharvest_cart <- function(query, idType = "AnyId", info = NULL) {
  chemicals <- NULL
  req_data <- run_hook(
    "chemi_resolver_universalharvest_cart",
    "pre_request",
    list(params = list(query = query, idType = idType, info = info, chemicals = chemicals))
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
  if ("info" %in% names(req_data$params)) {
    info <- req_data$params[["info"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(info)) {
    extra_options$info <- info
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "resolver/universalharvest_cart",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
