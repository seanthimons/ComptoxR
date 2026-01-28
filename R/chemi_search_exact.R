#' Search Exact
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
#' chemi_search_exact(smiles = "DTXSID7020182")
#' }
chemi_search_exact <- function(smiles, exportSmiles = NULL, exportMol = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(exportSmiles)) options[['exportSmiles']] <- exportSmiles
  if (!is.null(exportMol)) options[['exportMol']] <- exportMol
    result <- generic_request(
    endpoint = "search/exact",
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


