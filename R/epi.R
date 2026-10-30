#' Retrieve the EPI API specification and health
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return A list containing the API specification and runtime health extensions.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
epi <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "epi_burl", relative = "/"),
    auth = list()
  )
  result
}
