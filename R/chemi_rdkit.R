#' Generate descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param type Optional parameter
#' @param radius Optional parameter
#' @param bits Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_rdkit(smiles = "DTXSID7020182")
#' }
chemi_rdkit <- function(smiles, type = NULL, radius = NULL, bits = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(type)) options[['type']] <- type
  if (!is.null(radius)) options[['radius']] <- radius
  if (!is.null(bits)) options[['bits']] <- bits
    result <- generic_request(
    endpoint = "rdkit",
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


