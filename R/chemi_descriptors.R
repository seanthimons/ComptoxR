#' Descriptors
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param type Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @param format Optional parameter. Options: JSON, CSV, TSV (default: JSON)
#' @param timeout Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors(smiles = "DTXSID7020182")
#' }
chemi_descriptors <- function(smiles, type, headers = FALSE, format = "JSON", timeout = NULL) {
  generic_request(
    endpoint = "descriptors",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    type = type,
    headers = headers,
    format = format,
    timeout = timeout
  )
}




#' Descriptors
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Required parameter
#' @param chemicals Optional parameter
#' @param chemIdType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId
#' @param format Optional parameter. Options: JSON, CSV, TSV
#' @param options Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors_bulk(type = "DTXSID7020182")
#' }
chemi_descriptors_bulk <- function(type, chemicals = NULL, chemIdType = NULL, format = NULL, options = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) options$chemicals <- chemicals
  if (!is.null(chemIdType)) options$chemIdType <- chemIdType
  if (!is.null(format)) options$format <- format
  if (!is.null(options)) options$options <- options
  generic_chemi_request(
    query = type,
    endpoint = "descriptors",
    options = options,
    tidy = FALSE
  )
}


