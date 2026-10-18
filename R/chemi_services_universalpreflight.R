#' Chemi services universalpreflight
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_services_universalpreflight <- function(body) {
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- .api_validation$form_value(
      body,
      list(
        type = "object",
        required = list("files[]"),
        properties = list("files[]" = list(items = list(format = "binary", type = "string"), type = "array"))
      ),
      .api_validation$body_value,
      FALSE
    )
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/services/universalpreflight",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    body_media = "multipart/form-data",
    body_encoding = list("files[]" = list(style = "form", explode = TRUE)),
    form_schema = list(
      type = "object",
      required = list("files[]"),
      properties = list("files[]" = list(items = list(format = "binary", type = "string"), type = "array"))
    )
  )
  result
}
