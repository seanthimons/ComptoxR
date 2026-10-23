#' Fetch aliases for a chemical
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid dtxsid
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_alias()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_alias <- function(dtxsid = NULL) {
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(dtxsid = list(type = "string")),
    .api_validation$body_value,
    c(dtxsid = "query")
  )
  params <- base::list("dtxsid" = dtxsid)
  if (base::is.character(params[["dtxsid"]]) && base::any(!base::nzchar(params[["dtxsid"]]))) {
    base::stop("Empty query parameter: dtxsid")
  }
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/alias",
    path_params = base::list(),
    query = base::list("dtxsid" = params[["dtxsid"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
