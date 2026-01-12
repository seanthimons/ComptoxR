#' Generate descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate groups for
#' @param model Model to use for group prediction (default: RF)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_arn_cats(smiles = "DTXSID7020182")
#' }
chemi_arn_cats <- function(smiles, model = "RF") {
  generic_request(
    endpoint = "arn_cats",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    model = model
  )
}




#' Generate groups for multiple molecules
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
#' chemi_arn_cats_bulk(query = "DTXSID7020182")
#' }
chemi_arn_cats_bulk <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "arn_cats",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


