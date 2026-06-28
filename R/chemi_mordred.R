#' Generate descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param headers Optional parameter
#' @param inchi Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_mordred(smiles = "DTXSID7020182")
#' }
chemi_mordred <- function(smiles, headers = NULL, inchi = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(headers)) {
    options[['headers']] <- headers
  }
  if (!is.null(inchi)) {
    options[['inchi']] <- inchi
  }
  result <- generic_request(
    endpoint = "mordred",
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


#' Generate descriptors for multiple molecules
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
#' chemi_mordred_bulk(chemicals = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_mordred_bulk <- function(chemicals, options = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(options)) {
    options$options <- options
  }
  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "mordred",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
