#' Padel
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param x2d Optional parameter (default: TRUE)
#' @param x3d Optional parameter (default: FALSE)
#' @param fp Optional parameter (default: FALSE)
#' @param headers Optional parameter (default: FALSE)
#' @param timeout Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel(smiles = "DTXSID7020182")
#' }
chemi_padel <- function(smiles, x2d = TRUE, x3d = FALSE, fp = FALSE, headers = FALSE, timeout = NULL) {
  generic_request(
    endpoint = "padel",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    x2d = x2d,
    x3d = x3d,
    fp = fp,
    headers = headers,
    timeout = timeout
  )
}




#' Padel
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Required parameter
#' @param options Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel_bulk(chemicals = "DTXSID7020182")
#' }
chemi_padel_bulk <- function(chemicals, options = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(options)) options$options <- options
  generic_chemi_request(
    query = chemicals,
    endpoint = "padel",
    options = options,
    tidy = FALSE
  )
}


