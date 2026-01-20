#' Padel
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param x2d Optional parameter (default: TRUE)
#' @param x3d Optional parameter (default: FALSE)
#' @param fp Optional parameter (default: FALSE)
#' @param headers Optional parameter (default: FALSE)
#' @param timeout Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel(smiles = "DTXSID7020182")
#' }
chemi_padel <- function(smiles, x2d = TRUE, x3d = FALSE, fp = FALSE, headers = FALSE, timeout = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(x2d)) options[['2d']] <- x2d
  if (!is.null(x3d)) options[['3d']] <- x3d
  if (!is.null(fp)) options[['fp']] <- fp
  if (!is.null(headers)) options[['headers']] <- headers
  if (!is.null(timeout)) options[['timeout']] <- timeout
    result <- generic_request(
    query = NULL,
    endpoint = "padel",
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




#' Padel
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel_bulk()
#' }
chemi_padel_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "padel",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


