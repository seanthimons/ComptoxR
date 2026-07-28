#' Predict one chemical with WebTEST
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Wide output preserves every input position and expands successful inputs to
#' one row per requested prediction. Raw output preserves the upstream
#' `PredictionResult`.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param endpoint One required WebTEST endpoint identifier, such as `LC50`.
#' @param method Prediction method: `consensus`, `hc`, `sm`, `gc`, or `nn`.
#' @param format Response format. Only `JSON` is supported.
#' @param output Output contract: `wide` for normalized rows or `raw` for the
#'   upstream `PredictionResult` with source and input-map attributes.
#' @return A normalized tibble or raw WebTEST `PredictionResult`.
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict("DTXSID7020182", endpoint = "LC50")
#' }
chemi_webtest_predict <- function(
  smiles,
  endpoint,
  method = "consensus",
  format = "JSON",
  output = c("wide", "raw")
) {
  if (missing(endpoint)) {
    endpoint <- NULL
  }
  req_data <- run_hook(
    "chemi_webtest_predict",
    "pre_request",
    list(
      params = list(
        smiles = smiles,
        endpoint = endpoint,
        method = method,
        format = format,
        output = output
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

#' Predict multiple chemicals with WebTEST
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Wide output preserves every input position and expands successful inputs to
#' one row per requested prediction. Raw output preserves the upstream
#' `PredictionResult`.
#'
#' @param structures Chemical structures or resolvable identifiers.
#' @param endpoints Required WebTEST endpoint identifiers.
#' @param methods Optional prediction methods: `consensus`, `hc`, `sm`, `gc`,
#'   or `nn`. `NULL` retains every method returned by WebTEST.
#' @param format Response format. Only `JSON` is supported.
#' @param output Output contract: `wide` for normalized rows or `raw` for the
#'   upstream `PredictionResult` with source and input-map attributes.
#' @return A normalized tibble or raw WebTEST `PredictionResult`.
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict_bulk(
#'   structures = c("DTXSID7020182", "CCO"),
#'   endpoints = "LC50"
#' )
#' }
chemi_webtest_predict_bulk <- function(
  structures,
  endpoints,
  methods = NULL,
  format = "JSON",
  output = c("wide", "raw")
) {
  if (missing(endpoints)) {
    endpoints <- NULL
  }
  req_data <- run_hook(
    "chemi_webtest_predict_bulk",
    "pre_request",
    list(
      params = list(
        structures = structures,
        endpoints = endpoints,
        methods = methods,
        format = format,
        output = output
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
