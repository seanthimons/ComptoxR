#' getintegrityreports (GET)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_getintegrityreports <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/getintegrityreports",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
