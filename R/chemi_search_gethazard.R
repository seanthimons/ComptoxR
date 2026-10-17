#' Search Gethazard
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param sid sid
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_search_gethazard(sid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_search_gethazard <- function(sid) {
  if (base::is.null(sid)) {
    base::stop("Required input: sid")
  }
  .api_validation$parameter_values(
    base::list("sid" = sid),
    list(sid = list(type = "string")),
    .api_validation$body_value,
    c(sid = "query")
  )
  params <- base::list("sid" = sid)
  if (base::is.character(params[["sid"]]) && base::any(!base::nzchar(params[["sid"]]))) {
    base::stop("Empty query parameter: sid")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/search/gethazard",
    path_params = base::list(),
    query = base::list("sid" = params[["sid"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
