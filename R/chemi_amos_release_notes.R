#' Returns a list of release notes for AMOS
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_release_notes()
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_release_notes <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/amos/release_notes",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
