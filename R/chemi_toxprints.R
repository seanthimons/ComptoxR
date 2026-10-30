#' Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Calculates ToxPrint descriptors for one structure and preserves the API response envelope. Use chemi_toxprints_bulk for a row-per-chemical table.
#' @param smiles One SMILES string. DTXSID acceptance depends on the service deployment.
#' @param headers Include descriptor names in the response; defaults to FALSE.
#' @param profile Optional profile name; NULL uses the service default.
#' @return A list containing the API response envelope with service metadata, chemicals and optional descriptor headers.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints(smiles = "CCO")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints <- function(smiles, headers = FALSE, profile = NULL) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "headers" = headers, "profile" = profile),
    list(
      smiles = list(type = "string"),
      headers = list(default = FALSE, type = "boolean"),
      profile = list(type = "string")
    ),
    .api_validation$body_value,
    c(smiles = "query", headers = "query", profile = "query")
  )
  params <- base::list("smiles" = smiles, "headers" = headers, "profile" = profile)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["headers"]]) && base::any(!base::nzchar(params[["headers"]]))) {
    base::stop("Empty query parameter: headers")
  }
  if (base::is.character(params[["profile"]]) && base::any(!base::nzchar(params[["profile"]]))) {
    base::stop("Empty query parameter: profile")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/toxprints",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]], "headers" = params[["headers"]], "profile" = params[["profile"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    parameter_serialization = list(list(
      name = "headers",
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
