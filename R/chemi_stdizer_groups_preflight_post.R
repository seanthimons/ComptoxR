#' Chemi standardizer groups preflight
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON, text or raw bytes according to response media.
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_groups_preflight_post <- function(body) {
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
    path = "/api/stdizer/groups/preflight",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    body_media = "multipart/form-data",
    body_encoding = list(),
    form_schema = list(
      type = "object",
      required = list("files[]"),
      properties = list("files[]" = list(items = list(format = "binary", type = "string"), type = "array"))
    )
  )
  result
}
