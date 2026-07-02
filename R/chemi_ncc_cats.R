#' Generate NCC categories for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate NCC categories for
#' @param logp Octanol-water partition coefficient
#' @param ws Water solubility (mg/L)
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_ncc_cats(smiles = "DTXSID7020182")
#' }
chemi_ncc_cats <- function(smiles, logp = NULL, ws = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(logp)) {
    options[['logp']] <- logp
  }
  if (!is.null(ws)) {
    options[['ws']] <- ws
  }
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


#' Generate NCC categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Array of input chemicals with optional id, smiles, logp, and ws. Missing smiles are returned as item-level errors.
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_ncc_cats_bulk(chemicals = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_ncc_cats_bulk <- function(chemicals = NULL) {
  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "ncc_cats",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
