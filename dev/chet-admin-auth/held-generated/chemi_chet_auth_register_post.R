#' Register a user (POST)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Native canonical contract. Session and authorization behavior is server-defined; this function does not manage credentials or session state.
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_auth_register_post <- function(body) {
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- .api_validation$form_value(
      body,
      list(additionalProperties = TRUE, type = "object"),
      .api_validation$body_value,
      TRUE
    )
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/auth/register",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(
      diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"
    ),
    server_resolver = list(
      name = ".ct_server_url",
      key = "chemi_burl",
      relative = "/api/chet"
    ),
    body_media = "application/x-www-form-urlencoded",
    body_encoding = list(),
    form_schema = list(additionalProperties = TRUE, type = "object")
  )
  result
}
