#' Chemi search download mol by smiles
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param format format
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_search_download_mol_by_smiles <- function(smiles, format) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  if (base::is.null(format)) {
    base::stop("Required input: format")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "format" = format),
    list(smiles = list(type = "string"), format = list(type = "string")),
    .api_validation$body_value,
    c(smiles = "query", format = "query")
  )
  params <- base::list("smiles" = smiles, "format" = format)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["format"]]) && base::any(!base::nzchar(params[["format"]]))) {
    base::stop("Empty query parameter: format")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/search/download/mol-by-smiles",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]], "format" = params[["format"]]),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
