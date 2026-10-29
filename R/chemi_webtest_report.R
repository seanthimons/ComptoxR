#' Retrieve a previously generated WebTEST report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param structure structure
#' @param endpoint endpoint
#' @param method method
#' @param format format
#' @return Decoded JSON or text, raw binary bytes, or NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_webtest_report <- function(structure, endpoint, method = "consensus", format = "HTML") {
  if (base::is.null(structure)) {
    base::stop("Required input: structure")
  }
  if (base::is.null(endpoint)) {
    base::stop("Required input: endpoint")
  }
  .api_validation$parameter_values(
    base::list("structure" = structure, "endpoint" = endpoint, "method" = method, "format" = format),
    list(
      structure = list(type = "string"),
      endpoint = list(type = "string"),
      method = list(default = "consensus", type = "string"),
      format = list(
        default = "HTML",
        enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(structure = "query", endpoint = "query", method = "query", format = "query")
  )
  params <- base::list("structure" = structure, "endpoint" = endpoint, "method" = method, "format" = format)
  if (base::is.character(params[["structure"]]) && base::any(!base::nzchar(params[["structure"]]))) {
    base::stop("Empty query parameter: structure")
  }
  if (base::is.character(params[["endpoint"]]) && base::any(!base::nzchar(params[["endpoint"]]))) {
    base::stop("Empty query parameter: endpoint")
  }
  if (base::is.character(params[["method"]]) && base::any(!base::nzchar(params[["method"]]))) {
    base::stop("Empty query parameter: method")
  }
  if (base::is.character(params[["format"]]) && base::any(!base::nzchar(params[["format"]]))) {
    base::stop("Empty query parameter: format")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/webtest/report",
    path_params = base::list(),
    query = base::list(
      "structure" = params[["structure"]],
      "endpoint" = params[["endpoint"]],
      "method" = params[["method"]],
      "format" = params[["format"]]
    ),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
