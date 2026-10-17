#' Alerts Groups
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_alerts_groups <- function() {
  params <- base::list()
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/alerts/groups",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = NULL,
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = ".ct_static_list"
  )
  result
}
