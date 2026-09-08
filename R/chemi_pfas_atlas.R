#' Generate PFAS Atlas categories for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES string of the molecule
#' @return Returns a list with result object
#' @apiStage public
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
#' @param chemicals Either an array of input chemicals with optional id and required smiles, or an array of SMILES strings for backward compatibility.
#' @param smiles Array of SMILES strings, kept for backward compatibility with the previous PFAS Atlas POST format.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_atlas_bulk(chemicals = "DTXSID1024122")
#' }
chemi_pfas_atlas_bulk <- function(chemicals = NULL, smiles = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "pfas_atlas",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
