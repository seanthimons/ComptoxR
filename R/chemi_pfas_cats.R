#' Generate PFAS categories for one molecule
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
#' chemi_pfas_cats(smiles = "FC(C(C(C1OC(=O)C2C(=CC=CC=2)N=1)(F)F)(F)F)(F)F")
#' }
chemi_pfas_cats <- function(smiles) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  result <- generic_request(
    endpoint = "pfas_cats",
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


#' Generate PFAS categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Array of SMILES strings, kept for backward compatibility with the previous PFAS Cats POST format.
#' @param chemicals Either an array of input chemicals with optional id and required smiles, or an array of SMILES strings for backward compatibility.
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_cats_bulk(smiles = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_pfas_cats_bulk <- function(smiles = NULL, chemicals = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) {
    options$chemicals <- chemicals
  }
  result <- generic_chemi_request(
    query = smiles,
    endpoint = "pfas_cats",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
