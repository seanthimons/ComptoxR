#' Predictor Models Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @param model_id Model ID to use
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict(smiles = "DTXSID7020182")
#' }
chemi_predictor_models_predict <- function(smiles, model_id) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(model_id)) options[['model_id']] <- model_id
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




#' Generate predictions for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param model_id Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict_bulk(smiles = "DTXSID7020182")
#' }
chemi_predictor_models_predict_bulk <- function(smiles, model_id) {
  # Build options list for additional parameters
  options <- list()
  options$model_id <- model_id
  result <- generic_chemi_request(
    query = smiles,
    endpoint = "predictor_models/predict",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


