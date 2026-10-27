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
