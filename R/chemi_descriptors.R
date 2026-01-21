#' Descriptors
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param type Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @param format Optional parameter. Options: JSON, CSV, TSV (default: JSON)
#' @param timeout Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors(smiles = "DTXSID7020182")
#' }
chemi_descriptors <- function(smiles, type, headers = FALSE, format = "JSON", timeout = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(type)) options[['type']] <- type
  if (!is.null(headers)) options[['headers']] <- headers
  if (!is.null(format)) options[['format']] <- format
  if (!is.null(timeout)) options[['timeout']] <- timeout
    result <- generic_request(
    query = NULL,
    endpoint = "descriptors",
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




#' Descriptors
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors_bulk()
#' }
chemi_descriptors_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "descriptors",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


