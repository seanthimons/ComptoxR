#' View error page (GET)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Native canonical contract. Session and authorization behavior is server-defined; this function does not manage credentials or session state.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_auth_errorpage <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/auth/errorpage",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
