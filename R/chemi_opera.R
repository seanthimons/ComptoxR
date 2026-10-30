#' Opera
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param format format
#' @param standardize standardize
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_opera(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_opera <- function(smiles, format = "json", standardize = FALSE) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "format" = format, "standardize" = standardize),
    list(
      smiles = list(type = "string"),
      format = list(default = "json", type = "string"),
      standardize = list(default = FALSE, type = "boolean")
    ),
    .api_validation$body_value,
    c(smiles = "query", format = "query", standardize = "query")
  )
  params <- base::list("smiles" = smiles, "format" = format, "standardize" = standardize)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["format"]]) && base::any(!base::nzchar(params[["format"]]))) {
    base::stop("Empty query parameter: format")
  }
  if (base::is.character(params[["standardize"]]) && base::any(!base::nzchar(params[["standardize"]]))) {
    base::stop("Empty query parameter: standardize")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/opera",
    path_params = base::list(),
    query = base::list(
      "smiles" = params[["smiles"]],
      "format" = params[["format"]],
      "standardize" = params[["standardize"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list(),
    parameter_serialization = list(list(
      name = "standardize",
      location = "query",
      schema = list(default = FALSE, type = "boolean"),
      style = "form",
      explode = TRUE,
      collection_format = NULL,
      required = FALSE
    ))
  )
  result
}
