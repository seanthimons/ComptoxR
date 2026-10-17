#' Predictor Models Predict
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param model_id model_id
#' @param smiles smiles
#' @param identifier identifier
#' @param report_format report_format
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict(model_id = 1L)
#' }
# Generated with specmill; do not edit by hand.
chemi_predictor_models_predict <- function(model_id, smiles = NULL, identifier = NULL, report_format = "json") {
  if (base::is.null(model_id)) {
    base::stop("Required input: model_id")
  }
  .api_validation$parameter_values(
    base::list("model_id" = model_id, "smiles" = smiles, "identifier" = identifier, "report_format" = report_format),
    list(
      model_id = list(type = "integer"),
      smiles = list(type = "string"),
      identifier = list(type = "string"),
      report_format = list(default = "json", type = "string")
    ),
    .api_validation$body_value,
    c(model_id = "query", smiles = "query", identifier = "query", report_format = "query")
  )
  params <- base::list(
    "model_id" = model_id,
    "smiles" = smiles,
    "identifier" = identifier,
    "report_format" = report_format
  )
  if (base::is.character(params[["model_id"]]) && base::any(!base::nzchar(params[["model_id"]]))) {
    base::stop("Empty query parameter: model_id")
  }
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["identifier"]]) && base::any(!base::nzchar(params[["identifier"]]))) {
    base::stop("Empty query parameter: identifier")
  }
  if (base::is.character(params[["report_format"]]) && base::any(!base::nzchar(params[["report_format"]]))) {
    base::stop("Empty query parameter: report_format")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/predictor_models/predict",
    path_params = base::list(),
    query = base::list(
      "model_id" = params[["model_id"]],
      "smiles" = params[["smiles"]],
      "identifier" = params[["identifier"]],
      "report_format" = params[["report_format"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}

#' Generate predictions for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param model_id Required parameter
#' @param smiles Optional parameter
#' @param chemicals Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict_bulk(model_id = 1065L, smiles = c("CCO", "CCCC"))
#' }
# Generated with specmill; do not edit by hand.
chemi_predictor_models_predict_bulk <- function(model_id, smiles = NULL, chemicals = NULL) {
  params <- base::list("model_id" = model_id, "smiles" = smiles, "chemicals" = chemicals)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/predictor_models/predict",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      if (
        sum(c(
          all(!vapply(list(params[["smiles"]], params[["model_id"]]), is.null, logical(1))),
          all(!vapply(list(params[["chemicals"]], params[["model_id"]]), is.null, logical(1)))
        )) !=
          1L
      ) {
        cli::cli_abort("Supply exactly one supported request-body shape.")
      }
      base::Filter(
        base::Negate(base::is.null),
        base::list(model_id = params[["model_id"]], smiles = params[["smiles"]], chemicals = params[["chemicals"]])
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    "auth" = list(),
    "response_policy" = ".ct_prediction"
  )
  result
}
