#' List maps for a reaction
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param react_id react_id
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_react_maps()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_react_maps <- function(react_id = NULL) {
  .api_validation$parameter_values(
    base::list("react_id" = react_id),
    list(react_id = list(type = "string")),
    .api_validation$body_value,
    c(react_id = "query")
  )
  params <- base::list("react_id" = react_id)
  if (base::is.character(params[["react_id"]]) && base::any(!base::nzchar(params[["react_id"]]))) {
    base::stop("Empty query parameter: react_id")
  }
  result <- .ct_request(
    method = "GET",
    path = "/reaction/react_maps",
    path_params = base::list(),
    query = base::list("react_id" = params[["react_id"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
