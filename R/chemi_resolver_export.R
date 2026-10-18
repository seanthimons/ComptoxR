#' export (GET)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query query
#' @param idType idType
#' @param outputFormat outputFormat
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_export <- function(query, idType = "AnyId", outputFormat = "PDF") {
  if (base::is.null(query)) {
    base::stop("Required input: query")
  }
  .api_validation$parameter_values(
    base::list("query" = query, "idType" = idType, "outputFormat" = outputFormat),
    list(
      query = list(type = "string"),
      idType = list(
        default = "AnyId",
        enum = list("DTXSID", "DTXCID", "SMILES", "MOL", "CAS", "Name", "InChI", "InChIKey", "InChIKey_1", "AnyId"),
        type = "string"
      ),
      outputFormat = list(
        default = "PDF",
        enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(query = "query", idType = "query", outputFormat = "query")
  )
  params <- base::list("query" = query, "idType" = idType, "outputFormat" = outputFormat)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["idType"]]) && base::any(!base::nzchar(params[["idType"]]))) {
    base::stop("Empty query parameter: idType")
  }
  if (base::is.character(params[["outputFormat"]]) && base::any(!base::nzchar(params[["outputFormat"]]))) {
    base::stop("Empty query parameter: outputFormat")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/export",
    path_params = base::list(),
    query = base::list(
      "query" = params[["query"]],
      "idType" = params[["idType"]],
      "outputFormat" = params[["outputFormat"]]
    ),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
