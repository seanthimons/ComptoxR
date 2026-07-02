#' Generate PFAS Atlas categories for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES string of the molecule
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_atlas(smiles = "O=C(O)C(F)(F)C(F)(F)C(F)(F)C(F)(F)F")
#' }
chemi_pfas_atlas <- function(smiles) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  result <- generic_request(
    endpoint = "pfas_atlas",
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


#' Generate PFAS Atlas categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Array of SMILES strings, kept for backward compatibility with the previous PFAS Atlas POST format.
#' @param chemicals Either an array of input chemicals with optional id and required smiles, or an array of SMILES strings for backward compatibility.
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_atlas_bulk(smiles = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_pfas_atlas_bulk <- function(smiles = NULL, chemicals = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) {
    options$chemicals <- chemicals
  }
  result <- generic_chemi_request(
    query = smiles,
    endpoint = "pfas_atlas",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
