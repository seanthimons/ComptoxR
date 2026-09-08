#' Generate an ARN category for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate groups for
#' @param model Model to use for group prediction. Options: RF, NN (default: RF)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_arn_cats(smiles = "DTXSID7020182")
#' }
chemi_arn_cats <- function(smiles, model = "RF") {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(model)) {
    options[['model']] <- model
  }
  result <- generic_request(
    endpoint = "arn_cats",
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

#' Generate groups for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Array of objects with optional id and smiles, or an array of SMILES strings for backward compatibility.
#' @param model Optional parameter. Options: RF, NN (default: RF)
#' @param smiles Array of SMILES strings, same input style as amnb_nate.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_arn_cats_bulk(chemicals = "DTXSID1024122")
#' }
chemi_arn_cats_bulk <- function(chemicals = NULL, model = "RF", smiles = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(model)) {
    options$model <- model
  }
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "arn_cats",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
