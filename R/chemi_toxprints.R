#' Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints(smiles = "DTXSID7020182")
#' }
chemi_toxprints <- function(smiles, headers = FALSE, profile = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(headers)) options[['headers']] <- headers
  if (!is.null(profile)) options[['profile']] <- profile
    result <- generic_request(
    query = NULL,
    endpoint = "toxprints",
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




#' Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_bulk()
#' }
chemi_toxprints_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "toxprints",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


