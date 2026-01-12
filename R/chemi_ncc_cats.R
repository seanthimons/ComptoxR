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
#' chemi_ncc_cats(smiles = "DTXSID7020182")
#' }
chemi_ncc_cats <- function(smiles, logp, ws) {
  generic_request(
    endpoint = "ncc_cats",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    logp = logp,
    ws = ws
  )
}




#' Generate categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_ncc_cats_bulk(query = "DTXSID7020182")
#' }
chemi_ncc_cats_bulk <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "ncc_cats",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


