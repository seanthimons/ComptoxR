#' Generate an ARN category for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param model model
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_arn_cats(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_arn_cats <- function(smiles, model = "RF") {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "model" = model),
    list(smiles = list(type = "string"), model = list(default = "RF", enum = list("RF", "NN"), type = "string")),
    .api_validation$body_value,
    c(smiles = "query", model = "query")
  )
  params <- base::list("smiles" = smiles, "model" = model)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["model"]]) && base::any(!base::nzchar(params[["model"]]))) {
    base::stop("Empty query parameter: model")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/arn_cats",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]], "model" = params[["model"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}
