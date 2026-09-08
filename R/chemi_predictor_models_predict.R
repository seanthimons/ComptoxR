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
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict(smiles = "DTXSID7020182")
#' }
chemi_predictor_models_predict <- function(
  model_id,
  smiles = NULL,
  identifier = NULL,
  report_format = "json"
) {
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

#' Generate predictions for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param model_id Required parameter
#' @param smiles Optional parameter
#' @param chemicals Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_models_predict_bulk(model_id = "DTXSID1024122")
#' }
chemi_predictor_models_predict_bulk <- function(
  model_id,
  smiles = NULL,
  chemicals = NULL
) {
  if (
    sum(c(
      all(!vapply(list(smiles, model_id), is.null, logical(1))),
      all(!vapply(list(chemicals, model_id), is.null, logical(1)))
    )) !=
      1L
  ) {
    cli::cli_abort("Supply exactly one supported request-body shape.")
  }
  request_body <- Filter(
    Negate(is.null),
    list(model_id = model_id, smiles = smiles, chemicals = chemicals)
  )
  result <- generic_chemi_request(
    endpoint = "predictor_models/predict",
    body = request_body,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
