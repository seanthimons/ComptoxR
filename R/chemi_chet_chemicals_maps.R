#' Map list for a chemical
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemid chemid
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_maps()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_maps <- function(chemid = NULL) {
  .api_validation$parameter_values(
    base::list("chemid" = chemid),
    list(chemid = list(type = "string")),
    .api_validation$body_value,
    c(chemid = "query")
  )
  params <- base::list("chemid" = chemid)
  if (base::is.character(params[["chemid"]]) && base::any(!base::nzchar(params[["chemid"]]))) {
    base::stop("Empty query parameter: chemid")
  }
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/maps",
    path_params = base::list(),
    query = base::list("chemid" = params[["chemid"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
