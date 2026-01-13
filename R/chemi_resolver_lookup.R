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
  result <- generic_request(
    endpoint = "resolver/lookup",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    query = query,
    idType = idType,
    fuzzy = fuzzy,
    mol = mol
  )

  # Additional post-processing can be added here

  return(result)
}




#' Resolver Lookup
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param ids List of chemical identifiers to look up. All identifiers must be of the same type or type should be Any.
#' @param filters Optional parameter
#' @param format Optional parameter. Options: UNKNOWN, SDF, SMI, MOL, CSV, TSV, JSON, XLSX, PDF, HTML, XML, DOCX
#' @param fuzzy If set to true fuzzy lookup result is returned which usually means a substring search. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic
#' @param idsType Chemical identifier type. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId
#' @param mol If set to true then MOL is requested as a result
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_lookup_bulk(ids = "DTXSID7020182")
#' }
chemi_resolver_lookup_bulk <- function(ids, filters = NULL, format = NULL, fuzzy = NULL, idsType = NULL, mol = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(filters)) options$filters <- filters
  if (!is.null(format)) options$format <- format
  if (!is.null(fuzzy)) options$fuzzy <- fuzzy
  if (!is.null(idsType)) options$idsType <- idsType
  if (!is.null(mol)) options$mol <- mol
  result <- generic_chemi_request(
    query = ids,
    endpoint = "resolver/lookup",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


