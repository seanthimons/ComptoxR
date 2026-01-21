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
  # Build request body according to LookupRequest schema
  body <- list(
    ids = ids,
    idsType = idsType,
    fuzzy = fuzzy,
    mol = mol
  )
  
  # Add truly optional parameters
  if (!is.null(filters)) body$filters <- filters
  if (!is.null(format)) body$format <- format
  
  # Build and send request
  base_url <- Sys.getenv("chemi_burl", unset = "")
  if (base_url == "") base_url <- "chemi_burl"
  
  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("resolver/lookup") |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body) |>
    httr2::req_headers(Accept = "application/json")
  
  if (as.logical(Sys.getenv("run_debug", "FALSE"))) {
    return(httr2::req_dry_run(req))
  }
  
  resp <- httr2::req_perform(req)
  
  if (httr2::resp_status(resp) < 200 || httr2::resp_status(resp) >= 300) {
    cli::cli_abort("API request to {.val resolver/lookup} failed with status {httr2::resp_status(resp)}")
  }
  
  result <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  
  # Additional post-processing can be added here
  
  return(result)
}


