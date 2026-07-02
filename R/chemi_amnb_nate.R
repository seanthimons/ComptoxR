#' Amnb Nate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amnb_nate(smiles = "DTXSID7020182")
#' }
chemi_amnb_nate <- function(smiles) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  result <- generic_request(
    endpoint = "amnb_nate",
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


#' Generate predictions for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Optional parameter
#' @param chemicals Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amnb_nate_bulk(smiles = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_amnb_nate_bulk <- function(smiles = NULL, chemicals = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) {
    options$chemicals <- chemicals
  }
  result <- generic_chemi_request(
    query = smiles,
    endpoint = "amnb_nate",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
