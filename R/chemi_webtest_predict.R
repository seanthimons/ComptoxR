#' Predict one chemical with WebTEST
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' WebTEST may return endpoints and prediction methods beyond those requested.
#' This function filters those nested records while preserving the upstream
#' `PredictionResult` structure and metadata.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param endpoint One required WebTEST endpoint identifier, such as `LC50`.
#' @param method Prediction method: `consensus`, `hc`, `sm`, `gc`, or `nn`.
#' @param format Response format. Only `JSON` is supported.
#' @return A filtered upstream WebTEST `PredictionResult`.
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
  format = "JSON"
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
        format = format
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("endpoint" %in% names(req_data$params)) {
    endpoint <- req_data$params[["endpoint"]]
  }
  if ("method" %in% names(req_data$params)) {
    method <- req_data$params[["method"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }

  options <- list(
    smiles = smiles,
    endpoint = endpoint,
    method = method,
    format = format
  )
  result <- generic_request(
    endpoint = "webtest/predict",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  result <- run_hook(
    "chemi_webtest_predict",
    "post_response",
    list(
      result = result,
      params = list(
        smiles = smiles,
        endpoint = endpoint,
        method = method,
        format = format
      )
    )
  )

  return(result)
}

#' Predict multiple chemicals with WebTEST
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' WebTEST may return endpoints and prediction methods beyond those requested.
#' This function filters those nested records while preserving the upstream
#' `PredictionResult` structure and metadata.
#'
#' @param structures Chemical structures or resolvable identifiers.
#' @param endpoints Required WebTEST endpoint identifiers.
#' @param methods Optional prediction methods: `consensus`, `hc`, `sm`, `gc`,
#'   or `nn`. `NULL` retains every method returned by WebTEST.
#' @param format Response format. Only `JSON` is supported.
#' @return A filtered upstream WebTEST `PredictionResult`.
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
  format = "JSON"
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
        format = format
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("structures" %in% names(req_data$params)) {
    structures <- req_data$params[["structures"]]
  }
  if ("endpoints" %in% names(req_data$params)) {
    endpoints <- req_data$params[["endpoints"]]
  }
  if ("methods" %in% names(req_data$params)) {
    methods <- req_data$params[["methods"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }

  request_options <- list(
    endpoints = endpoints,
    methods = methods,
    format = format
  )
  result <- generic_chemi_request(
    query = structures,
    endpoint = "webtest/predict",
    options = request_options,
    sid_label = "structures",
    array_payload = TRUE,
    tidy = FALSE
  )

  result <- run_hook(
    "chemi_webtest_predict_bulk",
    "post_response",
    list(
      result = result,
      params = list(
        structures = structures,
        endpoints = endpoints,
        methods = methods,
        format = format
      )
    )
  )

  return(result)
}
