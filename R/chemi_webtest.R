#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest(smiles = "DTXSID7020182")
#' }
chemi_webtest <- function(smiles, headers = FALSE) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(headers)) options[['headers']] <- headers
    result <- generic_request(
    query = NULL,
    endpoint = "webtest",
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




#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_bulk()
#' }
chemi_webtest_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "webtest",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


