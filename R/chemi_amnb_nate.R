#' Amnb Nate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @return Returns a list with result object
#' @apiStage public
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
#' @param chemicals Optional parameter
#' @param smiles Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amnb_nate_bulk(chemicals = "DTXSID1024122")
#' }
chemi_amnb_nate_bulk <- function(chemicals = NULL, smiles = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "amnb_nate",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
