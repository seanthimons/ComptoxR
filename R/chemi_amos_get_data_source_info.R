#' Returns a list of major data sources in AMOS with some supplemental information
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_data_source_info()
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_data_source_info <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/amos/get_data_source_info/",
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
