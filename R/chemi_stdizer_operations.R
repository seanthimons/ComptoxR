#' Stdizer Operations
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_operations()
#' }
# Generated with specmill; do not edit by hand.
chemi_stdizer_operations <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/stdizer/operations",
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
