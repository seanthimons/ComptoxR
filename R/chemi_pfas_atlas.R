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
#' chemi_pfas_atlas(smiles = "DTXSID7020182")
#' }
chemi_pfas_atlas <- function(smiles) {
  generic_request(
    endpoint = "pfas_atlas",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles
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
#' chemi_pfas_atlas_bulk(query = "DTXSID7020182")
#' }
chemi_pfas_atlas_bulk <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "pfas_atlas",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


