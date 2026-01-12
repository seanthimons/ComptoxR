#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags(query = "DTXSID7020182")
#' }
chemi_resolver_safety_flags <- function(query, idType = "AnyId") {
  generic_request(
    endpoint = "resolver/safety-flags",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    query = query,
    idType = idType
  )
}




#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags_bulk(request = "DTXSID7020182")
#' }
chemi_resolver_safety_flags_bulk <- function(request) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request)) options[['request']] <- request
  generic_chemi_request(
    query = request,
    endpoint = "resolver/safety-flags",
    options = options,
    tidy = FALSE
  )
}


