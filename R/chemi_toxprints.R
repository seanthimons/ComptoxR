#' Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints(smiles = "DTXSID7020182")
#' }
chemi_toxprints <- function(smiles, headers = FALSE, profile = NULL) {
  result <- generic_request(
    endpoint = "toxprints",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    headers = headers,
    profile = profile
  )

  # Additional post-processing can be added here

  return(result)
}




#' Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Required parameter
#' @param profile Optional parameter
#' @param options Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_bulk(chemicals = c("DTXSID10900961", "DTXSID2042353", "DTXSID1022421"))
#' }
chemi_toxprints_bulk <- function(chemicals, profile = NULL, options = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(profile)) options$profile <- profile
  if (!is.null(options)) options$options <- options
  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "toxprints",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


