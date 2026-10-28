#' Returns a list of all unique fact sheet types, coming from the document_type field of the fact sheet table
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_list_fact_sheet_types()
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_list_fact_sheet_types <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/api/amos/list_fact_sheet_types/",
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
