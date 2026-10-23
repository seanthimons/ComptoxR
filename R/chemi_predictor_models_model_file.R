#' Retrieve a predictor model file
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param type_id type_id
#' @param model_id model_id
#' @return Decoded JSON or text, raw binary bytes, or NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_predictor_models_model_file <- function(type_id, model_id) {
  if (base::is.null(type_id)) {
    base::stop("Required input: type_id")
  }
  if (base::is.null(model_id)) {
    base::stop("Required input: model_id")
  }
  .api_validation$parameter_values(
    base::list("type_id" = type_id, "model_id" = model_id),
    list(type_id = list(type = "integer"), model_id = list(type = "integer")),
    .api_validation$body_value,
    c(type_id = "query", model_id = "query")
  )
  params <- base::list("type_id" = type_id, "model_id" = model_id)
  if (base::is.character(params[["type_id"]]) && base::any(!base::nzchar(params[["type_id"]]))) {
    base::stop("Empty query parameter: type_id")
  }
  if (base::is.character(params[["model_id"]]) && base::any(!base::nzchar(params[["model_id"]]))) {
    base::stop("Empty query parameter: model_id")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/predictor_models/model/file/",
    path_params = base::list(),
    query = base::list("type_id" = params[["type_id"]], "model_id" = params[["model_id"]]),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}
