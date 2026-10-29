#' Inspect the current CheT curator session
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Decoded JSON, text, or raw download bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_curators_me <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/curators/me",
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
