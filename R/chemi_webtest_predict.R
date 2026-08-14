#' Webtest Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param endpoint Optional parameter
#' @param method Optional parameter (default: consensus)
#' @param format Optional parameter. Options: JSON, HTML, PDF
#' @param output Output contract: normalized wide tibble or raw PredictionResult
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict(smiles = "DTXSID7020182")
#' }
chemi_webtest_predict <- function(smiles, endpoint, method = "consensus", format = "JSON", output = c("wide", "raw")) {
  server <- "chemi_burl"
  if (missing(endpoint)) {
    endpoint <- NULL
  }
  req_data <- run_hook(
    "chemi_webtest_predict",
    "pre_request",
    list(
      params = list(
        `smiles` = smiles,
        `endpoint` = endpoint,
        `method` = method,
        `format` = format,
        `output` = output,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    result <- req_data$result
  } else {
    result <- generic_request(
      endpoint = req_data$request$endpoint,
      method = "GET",
      batch_limit = 0,
      server = req_data$request$server,
      auth = FALSE,
      tidy = FALSE,
      options = req_data$request$options
    )
  }

  post_data <- req_data
  post_data$result <- result
  result <- run_hook("chemi_webtest_predict", "post_response", post_data)

  return(result)
}

#' Webtest Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param endpoints Endpoint to predict
#' @param structures Molecule expressed as SMILES or MOL
#' @param format Report type: JSON, HTML or PDF. Options: JSON, HTML, PDF
#' @param methods Prediction method: hc (Hierarchical Clustering), sm (Single Model), nn (Nearest Neighbour), gc (Group Contribution) or consensus (Default)
#' @param output Output contract: normalized wide tibble or raw PredictionResult
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict_bulk(endpoints = "DTXSID1024122")
#' }
chemi_webtest_predict_bulk <- function(
  structures,
  endpoints,
  methods = NULL,
  format = "JSON",
  output = c("wide", "raw")
) {
  server <- "chemi_burl"
  if (missing(endpoints)) {
    endpoints <- NULL
  }
  req_data <- run_hook(
    "chemi_webtest_predict_bulk",
    "pre_request",
    list(
      params = list(
        `structures` = structures,
        `endpoints` = endpoints,
        `methods` = methods,
        `format` = format,
        `output` = output,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    result <- req_data$result
  } else {
    result <- generic_chemi_request(
      endpoint = req_data$request$endpoint,
      server = req_data$request$server,
      auth = FALSE,
      tidy = FALSE,
      body = req_data$request$body
    )
  }

  post_data <- req_data
  post_data$result <- result
  result <- run_hook("chemi_webtest_predict_bulk", "post_response", post_data)

  return(result)
}
