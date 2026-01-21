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
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}




#' Resolver Lookup (Bulk)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Performs bulk lookup of chemical identifiers via POST endpoint.
#'
#' @param ids Character vector of chemical identifiers to look up. All identifiers must be of the same type or type should be AnyId.
#' @param idsType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param fuzzy Fuzzy lookup setting. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)
#' @param mol If TRUE, MOL is requested as a result (default: FALSE)
#' @param filters Optional filters object
#' @param format Optional format specification. Options: UNKNOWN, SDF, SMI, MOL, CSV, TSV, JSON, XLSX, PDF, HTML, XML, DOCX
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_lookup_bulk(ids = c("DTXSID7020182", "50-00-0"))
#' }
chemi_resolver_lookup_bulk <- function(ids, idsType = "AnyId", fuzzy = "Not", mol = FALSE, filters = NULL, format = NULL) {
  # Input validation
  if (is.null(ids) || length(ids) == 0) {
    cli::cli_abort("ids must be a non-empty character vector")
  }
  
  # Convert to character vector if needed
  ids <- as.character(ids)
  
  # Build options list with all parameters
  options <- list(
    idsType = idsType,
    fuzzy = fuzzy,
    mol = mol
  )
  
  # Add truly optional parameters
  if (!is.null(filters)) options$filters <- filters
  if (!is.null(format)) options$format <- format
  
  # Use generic_chemi_request with array_payload format
  result <- generic_chemi_request(
    query = ids,
    endpoint = "resolver/lookup",
    options = options,
    sid_label = "ids",
    array_payload = TRUE,
    tidy = FALSE
  )
  
  # Additional post-processing can be added here
  
  return(result)
}


