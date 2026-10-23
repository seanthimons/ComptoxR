#' List chemicals by library
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param setid setid
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_chemset()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_chemset <- function(setid = NULL) {
  .api_validation$parameter_values(
    base::list("setid" = setid),
    list(setid = list(type = "string")),
    .api_validation$body_value,
    c(setid = "query")
  )
  params <- base::list("setid" = setid)
  if (base::is.character(params[["setid"]]) && base::any(!base::nzchar(params[["setid"]]))) {
    base::stop("Empty query parameter: setid")
  }
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/chemset",
    path_params = base::list(),
    query = base::list("setid" = params[["setid"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
