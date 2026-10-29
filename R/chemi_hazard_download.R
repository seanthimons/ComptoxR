#' Download a hazard report file
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param file file
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_hazard_download <- function(file) {
  if (base::is.null(file)) {
    base::stop("Required input: file")
  }
  .api_validation$parameter_values(
    base::list("file" = file),
    list(file = list(type = "string")),
    .api_validation$body_value,
    c(file = "query")
  )
  params <- base::list("file" = file)
  if (base::is.character(params[["file"]]) && base::any(!base::nzchar(params[["file"]]))) {
    base::stop("Empty query parameter: file")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/hazard/download",
    path_params = base::list(),
    query = base::list("file" = params[["file"]]),
    body = NULL,
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
