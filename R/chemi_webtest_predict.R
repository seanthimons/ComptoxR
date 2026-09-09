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
# Generated with apipak; do not edit by hand.
chemi_webtest_predict <- function(smiles, endpoint, method = "consensus", format = "JSON", output = c("wide", "raw")) {
  if (missing(endpoint)) {
    endpoint <- NULL
  }
  params <- list("smiles" = smiles, "endpoint" = endpoint, "method" = method, "format" = format, "output" = output)
  state <- run_hook("chemi_webtest_predict", "pre_request", list(params = params))
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  if (isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- generic_request(
      "endpoint" = state[["request"]][["endpoint"]],
      "method" = "GET",
      "batch_limit" = 0,
      "server" = state[["request"]][["server"]],
      "auth" = FALSE,
      "tidy" = FALSE,
      "options" = state[["request"]][["options"]]
    )
  }
  state["result"] <- list(result)
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
# Generated with apipak; do not edit by hand.
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
  params <- list(
    "structures" = structures,
    "endpoints" = endpoints,
    "methods" = methods,
    "format" = format,
    "output" = output
  )
  state <- run_hook("chemi_webtest_predict_bulk", "pre_request", list(params = params))
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  if (isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- generic_chemi_request(
      "endpoint" = state[["request"]][["endpoint"]],
      "server" = state[["request"]][["server"]],
      "auth" = FALSE,
      "tidy" = FALSE,
      "body" = state[["request"]][["body"]]
    )
  }
  state["result"] <- list(result)
  result <- run_hook("chemi_webtest_predict_bulk", "post_response", state)
  result
}
