#' Fetch temporary chemical details
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param type type
#' @param value value
#' @return Decoded JSON, text, or raw download bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_chemtemp <- function(type, value) {
  if (base::is.null(type)) {
    base::stop("Required input: type")
  }
  if (base::is.null(value)) {
    base::stop("Required input: value")
  }
  .api_validation$parameter_values(
    base::list("type" = type, "value" = value),
    list(type = list(type = "string"), value = list(type = "string")),
    .api_validation$body_value,
    c(type = "path", value = "path")
  )
  params <- base::list("type" = type, "value" = value)
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/chemtemp/{type}/{value}",
    path_params = base::list("type" = params[["type"]], "value" = params[["value"]]),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
