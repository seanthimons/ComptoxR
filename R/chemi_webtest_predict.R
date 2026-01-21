#' Webtest Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param endpoint Optional parameter
#' @param method Optional parameter (default: consensus)
#' @param format Optional parameter. Options: JSON, HTML, PDF
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict(smiles = "DTXSID7020182")
#' }
chemi_webtest_predict <- function(smiles, endpoint = NULL, method = "consensus", format = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(endpoint)) options[['endpoint']] <- endpoint
  if (!is.null(method)) options[['method']] <- method
  if (!is.null(format)) options[['format']] <- format
    result <- generic_request(
    query = NULL,
    endpoint = "webtest/predict",
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




#' Webtest Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict_bulk()
#' }
chemi_webtest_predict_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "webtest/predict",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


