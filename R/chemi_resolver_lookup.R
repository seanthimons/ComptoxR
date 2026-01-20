#' Resolver Lookup
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param fuzzy Optional parameter. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)
#' @param mol Optional parameter (default: FALSE)
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_lookup(query = "DTXSID7020182")
#' }
chemi_resolver_lookup <- function(query, idType = "AnyId", fuzzy = "Not", mol = FALSE) {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(idType)) options[['idType']] <- idType
  if (!is.null(fuzzy)) options[['fuzzy']] <- fuzzy
  if (!is.null(mol)) options[['mol']] <- mol
    result <- generic_request(
    query = NULL,
    endpoint = "resolver/lookup",
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




#' Resolver Lookup
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_lookup_bulk()
#' }
chemi_resolver_lookup_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "resolver/lookup",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


