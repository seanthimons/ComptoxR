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
    endpoint = "toxprints",
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




#' Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_bulk(query = "DTXSID7020182")
#' }
chemi_toxprints_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "toxprints",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


