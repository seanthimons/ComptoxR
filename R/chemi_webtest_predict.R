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
