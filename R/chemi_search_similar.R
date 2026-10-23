#' Search Similar
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param dtxsid dtxsid
#' @param exportSmiles exportSmiles
#' @param exportMol exportMol
#' @param min min
#' @param max max
#' @param similarityType similarityType
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_search_similar()
#' }
# Generated with specmill; do not edit by hand.
chemi_search_similar <- function(
  smiles = NULL,
  dtxsid = NULL,
  exportSmiles = NULL,
  exportMol = NULL,
  min = NULL,
  max = NULL,
  similarityType = NULL
) {
  .api_validation$parameter_values(
    base::list(
      "smiles" = smiles,
      "dtxsid" = dtxsid,
      "exportSmiles" = exportSmiles,
      "exportMol" = exportMol,
      "min" = min,
      "max" = max,
      "similarityType" = similarityType
    ),
    list(
      smiles = list(type = "string"),
      dtxsid = list(type = "string"),
      exportSmiles = list(type = "string"),
      exportMol = list(type = "string"),
      min = list(format = "float", type = "number"),
      max = list(format = "float", type = "number"),
      similarityType = list(type = "string")
    ),
    .api_validation$body_value,
    c(
      smiles = "query",
      dtxsid = "query",
      exportSmiles = "query",
      exportMol = "query",
      min = "query",
      max = "query",
      similarityType = "query"
    )
  )
  params <- base::list(
    "smiles" = smiles,
    "dtxsid" = dtxsid,
    "exportSmiles" = exportSmiles,
    "exportMol" = exportMol,
    "min" = min,
    "max" = max,
    "similarityType" = similarityType
  )
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["dtxsid"]]) && base::any(!base::nzchar(params[["dtxsid"]]))) {
    base::stop("Empty query parameter: dtxsid")
  }
  if (base::is.character(params[["exportSmiles"]]) && base::any(!base::nzchar(params[["exportSmiles"]]))) {
    base::stop("Empty query parameter: exportSmiles")
  }
  if (base::is.character(params[["exportMol"]]) && base::any(!base::nzchar(params[["exportMol"]]))) {
    base::stop("Empty query parameter: exportMol")
  }
  if (base::is.character(params[["min"]]) && base::any(!base::nzchar(params[["min"]]))) {
    base::stop("Empty query parameter: min")
  }
  if (base::is.character(params[["max"]]) && base::any(!base::nzchar(params[["max"]]))) {
    base::stop("Empty query parameter: max")
  }
  if (base::is.character(params[["similarityType"]]) && base::any(!base::nzchar(params[["similarityType"]]))) {
    base::stop("Empty query parameter: similarityType")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/search/similar",
    path_params = base::list(),
    query = base::list(
      "smiles" = params[["smiles"]],
      "dtxsid" = params[["dtxsid"]],
      "exportSmiles" = params[["exportSmiles"]],
      "exportMol" = params[["exportMol"]],
      "min" = params[["min"]],
      "max" = params[["max"]],
      "similarityType" = params[["similarityType"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
