#' Returns a summary of the records in the database, organized by record types, methodologies, and sources
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_database_summary()
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_database_summary <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/amos/database_summary/",
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
