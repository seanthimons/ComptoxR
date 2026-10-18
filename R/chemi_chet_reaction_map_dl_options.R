#' Inspect CheT map_DL preflight
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Decoded response; NULL for an empty preflight response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_map_dl_options <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "OPTIONS",
    path = "/reaction/map_DL",
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
