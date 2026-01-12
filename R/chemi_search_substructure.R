#' Search Substructure
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_substructure(smiles = "DTXSID7020182")
#' }
chemi_search_substructure <- function(smiles, exportSmiles = NULL, exportMol = NULL) {
  generic_request(
    endpoint = "search/substructure",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    exportSmiles = exportSmiles,
    exportMol = exportMol
  )
}


