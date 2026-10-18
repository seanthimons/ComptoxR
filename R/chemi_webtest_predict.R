#' Webtest Predict
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles Required parameter
#' @param endpoint Optional parameter
#' @param method Optional parameter (default: consensus)
#' @param format Optional parameter. Options: UNKNOWN, SDF, SMI, MOL, CSV, TSV, JSON, XLSX, PDF, HTML, XML, DOCX
#' @param output Output contract: normalized wide tibble or raw PredictionResult
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_webtest_predict(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_webtest_predict <- function(smiles, endpoint, method = "consensus", format = "JSON", output = c("wide", "raw")) {
  if (base::missing(endpoint)) {
    endpoint <- NULL
  }
  params <- base::list(
    "smiles" = smiles,
    "endpoint" = endpoint,
    "method" = method,
    "format" = format,
    "output" = output
  )
  state <- run_hook("chemi_webtest_predict", "pre_request", base::list(params = params))
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- .ct_request(
      "method" = "GET",
      "path" = state[["request"]][["endpoint"]],
      "path_params" = structure(list(), names = character(0)),
      "query" = state[["request"]][["options"]],
      "body" = NULL,
      "headers" = list(Accept = "application/json"),
      "server" = base::list("url" = state[["request"]][["server"]]),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        .ct_static_json_result(response, context, decode, state$request$endpoint)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_webtest_predict", "post_response", state)
  result
}

#' Webtest Predict
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param structures Molecule expressed as SMILES or MOL
#' @param endpoints Endpoint to predict
#' @param methods Prediction method: hc (Hierarchical Clustering), sm (Single Model), nn (Nearest Neighbour), gc (Group Contribution) or consensus (Default)
#' @param format Report type: JSON, HTML or PDF. Options: UNKNOWN, SDF, SMI, MOL, CSV, TSV, JSON, XLSX, PDF, HTML, XML, DOCX
#' @param output Output contract: normalized wide tibble or raw PredictionResult
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_webtest_predict_bulk(endpoints = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_webtest_predict_bulk <- function(
  structures,
  endpoints,
  methods = NULL,
  format = "JSON",
  output = c("wide", "raw")
) {
  if (base::missing(endpoints)) {
    endpoints <- NULL
  }
  params <- base::list(
    "structures" = structures,
    "endpoints" = endpoints,
    "methods" = methods,
    "format" = format,
    "output" = output
  )
  state <- run_hook("chemi_webtest_predict_bulk", "pre_request", base::list(params = params))
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- .ct_request(
      "method" = "POST",
      "path" = state[["request"]][["endpoint"]],
      "path_params" = structure(list(), names = character(0)),
      "query" = structure(list(), names = character(0)),
      "body" = state[["request"]][["body"]],
      "headers" = list(Accept = "application/json"),
      "server" = base::list("url" = state[["request"]][["server"]]),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        if (context$status >= 400L) {
          decode()
        }
        context$endpoint <- "webtest/predict"
        .ct_chemi_result(response, context, decode, tidy = FALSE)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_webtest_predict_bulk", "post_response", state)
  result
}
