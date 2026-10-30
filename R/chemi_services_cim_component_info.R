#' Services Cim Component Info
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_services_cim_component_info()
#' }
# Generated with specmill; do not edit by hand.
chemi_services_cim_component_info <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/services/cim_component_info",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    response_policy = ".ct_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
