#' Search Similar
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter
#' @param min Optional parameter
#' @param max Optional parameter
#' @param similarityType Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_similar(smiles = "DTXSID7020182")
#' }
chemi_search_similar <- function(smiles, exportSmiles = NULL, exportMol = NULL, min = NULL, max = NULL, similarityType = NULL) {
  generic_request(
    endpoint = "search/similar",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    exportSmiles = exportSmiles,
    exportMol = exportMol,
    min = min,
    max = max,
    similarityType = similarityType
  )
}


