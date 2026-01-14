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
  result <- generic_request(
    endpoint = "webtest/predict",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    smiles = smiles,
    endpoint = endpoint,
    method = method,
    format = format
  )

  # Additional post-processing can be added here

  return(result)
}




#' Webtest Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param structures Molecule expressed as SMILES or MOL
#' @param endpoints Endpoint to predict
#' @param methods Prediction method: hc (Hierarchical Clustering), sm (Single Model), nn (Nearest Neighbour), gc (Group Contribution) or consensus (Default)
#' @param format Report type: JSON, HTML or PDF. Options: JSON, HTML, PDF
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict_bulk(structures = c("DTXSID80880049", "DTXSID70963875", "DTXSID40292184"))
#' }
chemi_webtest_predict_bulk <- function(structures, endpoints, methods = NULL, format = NULL) {
  # Build options list for additional parameters
  options <- list()
  options$endpoints <- endpoints
  if (!is.null(methods)) options$methods <- methods
  if (!is.null(format)) options$format <- format
  result <- generic_chemi_request(
    query = structures,
    endpoint = "webtest/predict",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


