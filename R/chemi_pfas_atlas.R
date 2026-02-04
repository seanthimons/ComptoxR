#' Generate categories for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES string of the molecule
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_atlas(smiles = "Fc1c(F)c(F)c2c(c1F)C(F)(F)C(F)(Br)C2(Cl)Cl")
#' }
chemi_pfas_atlas <- function(smiles) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
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




#' Generate categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_atlas_bulk(smiles = c("DTXSID80161401", "DTXSID00205033", "DTXSID10185731"))
#' }
chemi_pfas_atlas_bulk <- function(smiles) {

  result <- generic_chemi_request(
    query = smiles,
    endpoint = "pfas_atlas",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


