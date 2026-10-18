#' export section (GET)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param sid sid
#' @param section section
#' @param outputFormat outputFormat
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_export_section <- function(sid, section = NULL, outputFormat = NULL) {
  if (base::is.null(sid)) {
    base::stop("Required input: sid")
  }
  .api_validation$parameter_values(
    base::list("sid" = sid, "section" = section, "outputFormat" = outputFormat),
    list(
      sid = list(type = "string"),
      section = list(type = "string"),
      outputFormat = list(
        enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(sid = "query", section = "query", outputFormat = "query")
  )
  params <- base::list("sid" = sid, "section" = section, "outputFormat" = outputFormat)
  if (base::is.character(params[["sid"]]) && base::any(!base::nzchar(params[["sid"]]))) {
    base::stop("Empty query parameter: sid")
  }
  if (base::is.character(params[["section"]]) && base::any(!base::nzchar(params[["section"]]))) {
    base::stop("Empty query parameter: section")
  }
  if (base::is.character(params[["outputFormat"]]) && base::any(!base::nzchar(params[["outputFormat"]]))) {
    base::stop("Empty query parameter: outputFormat")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/export-section",
    path_params = base::list(),
    query = base::list(
      "sid" = params[["sid"]],
      "section" = params[["section"]],
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
