#' List hazard report protocols
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_hazard_reports <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/hazard/reports",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
