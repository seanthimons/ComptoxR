#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags(query = "DTXSID7020182")
#' }
chemi_resolver_safety_flags <- function(query, idType = "AnyId") {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(idType)) options[['idType']] <- idType
    result <- generic_request(
    query = NULL,
    endpoint = "resolver/safety-flags",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}




#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request.filesInfo Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags_bulk(request.filesInfo = "DTXSID7020182")
#' }
chemi_resolver_safety_flags_bulk <- function(request.filesInfo) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request.filesInfo)) options[['request.filesInfo']] <- request.filesInfo
    result <- generic_chemi_request(
    query = NULL,
    endpoint = "resolver/safety-flags",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


