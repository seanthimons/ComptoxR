#' Generate categories for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES string of the molecule
#' @param logp Octanol-water partition coefficient
#' @param ws Water solubility (mg/L)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_ncc_cats(smiles = "C1=CC=CC=C1C(C1C=CC=CC=1)C1C=CC=CC=1")
#' }
chemi_ncc_cats <- function(smiles, logp, ws) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(logp)) options[['logp']] <- logp
  if (!is.null(ws)) options[['ws']] <- ws
    result <- generic_request(
    endpoint = "ncc_cats",
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
#' @param logp Required parameter
#' @param ws Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_ncc_cats_bulk(smiles = "DTXSID7020182")
#' }
chemi_ncc_cats_bulk <- function(smiles, logp, ws) {
  # Build options list for additional parameters
  options <- list()
  options$logp <- logp
  options$ws <- ws
  result <- generic_chemi_request(
    query = smiles,
    endpoint = "ncc_cats",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


