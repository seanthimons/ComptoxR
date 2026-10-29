#' Download the running EPI application JAR
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return The exact JAR bytes as a raw vector.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
epi_download <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/download",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "epi_burl", relative = "/"),
    auth = list()
  )
  result
}
