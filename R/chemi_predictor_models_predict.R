#' Predictor Models Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @param identifier identifier to generate predictions for
#' @param model_id Model ID to use
#' @param report_format which format to return (default: json)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict(smiles = "DTXSID7020182")
#' }
chemi_predictor_models_predict <- function(model_id, smiles = NULL, identifier = NULL, report_format = "json") {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(identifier)) {
    options[['identifier']] <- identifier
  }
  if (!is.null(model_id)) {
    options[['model_id']] <- model_id
  }
  if (!is.null(report_format)) {
    options[['report_format']] <- report_format
  }
  result <- generic_request(
    endpoint = "predictor_models/predict",
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
