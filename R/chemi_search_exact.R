#' Search Exact
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param exportSmiles exportSmiles
#' @param exportMol exportMol
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_search_exact(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_search_exact <- function(smiles, exportSmiles = NULL, exportMol = NULL) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "exportSmiles" = exportSmiles, "exportMol" = exportMol),
    list(smiles = list(type = "string"), exportSmiles = list(type = "string"), exportMol = list(type = "string")),
    .api_validation$body_value,
    c(smiles = "query", exportSmiles = "query", exportMol = "query")
  )
  params <- base::list("smiles" = smiles, "exportSmiles" = exportSmiles, "exportMol" = exportMol)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["exportSmiles"]]) && base::any(!base::nzchar(params[["exportSmiles"]]))) {
    base::stop("Empty query parameter: exportSmiles")
  }
  if (base::is.character(params[["exportMol"]]) && base::any(!base::nzchar(params[["exportMol"]]))) {
    base::stop("Empty query parameter: exportMol")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/search/exact",
    path_params = base::list(),
    query = base::list(
      "smiles" = params[["smiles"]],
      "exportSmiles" = params[["exportSmiles"]],
      "exportMol" = params[["exportMol"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
