#' List all chemicals (legacy)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database_old()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_database_old <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/database-old",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
