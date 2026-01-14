#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest(smiles = "DTXSID7020182")
#' }
chemi_webtest <- function(smiles, headers = FALSE) {
  result <- generic_request(
    endpoint = "webtest",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    headers = headers
  )

  # Additional post-processing can be added here

  return(result)
}




#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Required parameter
#' @param chemicals Optional parameter
#' @param format Optional parameter. Options: JSON, CSV, TSV
#' @param options Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_bulk(type = c("DTXSID3039242", "DTXSID10894891", "DTXSID20152651"))
#' }
chemi_webtest_bulk <- function(type, chemicals = NULL, format = NULL, options = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) options$chemicals <- chemicals
  if (!is.null(format)) options$format <- format
  if (!is.null(options)) options$options <- options
  result <- generic_chemi_request(
    query = type,
    endpoint = "webtest",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


