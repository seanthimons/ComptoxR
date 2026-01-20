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
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(exportSmiles)) options[['exportSmiles']] <- exportSmiles
  if (!is.null(exportMol)) options[['exportMol']] <- exportMol
  if (!is.null(min)) options[['min']] <- min
  if (!is.null(max)) options[['max']] <- max
  if (!is.null(similarityType)) options[['similarityType']] <- similarityType
    result <- generic_request(
    query = NULL,
    endpoint = "search/similar",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


