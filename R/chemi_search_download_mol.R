#' Chemi search download mol
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id
#' @param format format
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_search_download_mol <- function(id, format) {
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  if (base::is.null(format)) {
    base::stop("Required input: format")
  }
  .api_validation$parameter_values(
    base::list("id" = id, "format" = format),
    list(id = list(format = "int32", type = "integer"), format = list(type = "string")),
    .api_validation$body_value,
    c(id = "query", format = "query")
  )
  params <- base::list("id" = id, "format" = format)
  if (base::is.character(params[["id"]]) && base::any(!base::nzchar(params[["id"]]))) {
    base::stop("Empty query parameter: id")
  }
  if (base::is.character(params[["format"]]) && base::any(!base::nzchar(params[["format"]]))) {
    base::stop("Empty query parameter: format")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/search/download/mol",
    path_params = base::list(),
    query = base::list("id" = params[["id"]], "format" = params[["format"]]),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
