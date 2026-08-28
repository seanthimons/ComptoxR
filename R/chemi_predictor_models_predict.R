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
chemi_predictor_models_predict <- function(model_id, smiles = NULL, identifier = NULL, report_format = "json") {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_predictor_models_predict", "pre_request", list(params = list(`model_id` = model_id, `smiles` = smiles, `identifier` = identifier, `report_format` = report_format, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("model_id" %in% names(req_data$params)) {
    model_id <- req_data$params[["model_id"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("identifier" %in% names(req_data$params)) {
    identifier <- req_data$params[["identifier"]]
  }
  if ("report_format" %in% names(req_data$params)) {
    report_format <- req_data$params[["report_format"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(identifier)) options[['identifier']] <- identifier
  if (!is.null(model_id)) options[['model_id']] <- model_id
  if (!is.null(report_format)) options[['report_format']] <- report_format
    result <- generic_request(
    endpoint = "predictor_models/predict",
    method = "GET",
    batch_limit = 0,
    server = server,
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
chemi_predictor_models_predict_bulk <- function(model_id, smiles = NULL, chemicals = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_predictor_models_predict_bulk", "pre_request", list(params = list(`model_id` = model_id, `smiles` = smiles, `chemicals` = chemicals, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("model_id" %in% names(req_data$params)) {
    model_id <- req_data$params[["model_id"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  if (sum(c(all(!vapply(list(smiles, model_id), is.null, logical(1))), all(!vapply(list(chemicals, model_id), is.null, logical(1))))) != 1L) {
    cli::cli_abort("Supply exactly one supported request-body shape.")
  }
  request_body <- Filter(
    Negate(is.null),
    list(model_id = model_id, smiles = smiles, chemicals = chemicals)
  )
  result <- generic_chemi_request(
    endpoint = "predictor_models/predict",
    body = request_body,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
