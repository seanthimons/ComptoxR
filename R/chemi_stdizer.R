#' Stdizer
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param workflow workflow
#' @param smiles smiles
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer(workflow = "qsar-ready", smiles = "CCO")
#' }
# Generated with specmill; do not edit by hand.
chemi_stdizer <- function(workflow, smiles) {
  if (base::is.null(workflow)) {
    base::stop("Required input: workflow")
  }
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("workflow" = workflow, "smiles" = smiles),
    list(workflow = list(type = "string"), smiles = list(type = "string")),
    .api_validation$body_value,
    c(workflow = "query", smiles = "query")
  )
  params <- base::list("workflow" = workflow, "smiles" = smiles)
  if (base::is.character(params[["workflow"]]) && base::any(!base::nzchar(params[["workflow"]]))) {
    base::stop("Empty query parameter: workflow")
  }
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/stdizer",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list("workflow" = params[["workflow"]], "smiles" = params[["smiles"]]),
    "body" = NULL,
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = ".ct_static_list"
  )
  result
}
