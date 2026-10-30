#' Generate PFAS Atlas categories for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_pfas_atlas(smiles = "O=C(O)C(F)(F)C(F)(F)C(F)(F)C(F)(F)F")
#' }
# Generated with specmill; do not edit by hand.
chemi_pfas_atlas <- function(smiles) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles),
    list(smiles = list(type = "string")),
    .api_validation$body_value,
    c(smiles = "query")
  )
  params <- base::list("smiles" = smiles)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/pfas_atlas",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}
