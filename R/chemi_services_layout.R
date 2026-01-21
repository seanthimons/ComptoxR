#' Services Layout
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_layout(smiles = "DTXSID7020182")
#' }
chemi_services_layout <- function(smiles) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
    result <- generic_request(
    query = NULL,
    endpoint = "services/layout",
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


