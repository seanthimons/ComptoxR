#' Predictor Models Predict
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param model_id Model ID to use
#' @param smiles SMILES to generate predictions for
#' @param identifier identifier to generate predictions for
#' @param report_format which format to return (default: json)
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_predictor_models_predict <- function(model_id, smiles = NULL, identifier = NULL, report_format = "json") {
  params <- base::list(
    "model_id" = model_id,
    "smiles" = smiles,
    "identifier" = identifier,
    "report_format" = report_format
  )
  result <- generic_request(
    "endpoint" = "predictor_models/predict",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list(
          "smiles" = params[["smiles"]],
          "identifier" = params[["identifier"]],
          "model_id" = params[["model_id"]],
          "report_format" = params[["report_format"]]
        )
      )
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
