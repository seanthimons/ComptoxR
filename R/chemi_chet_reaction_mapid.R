#' List reactions for a map
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param map_id map_id
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mapid()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_mapid <- function(map_id = NULL) {
  .api_validation$parameter_values(
    base::list("map_id" = map_id),
    list(map_id = list(type = "string")),
    .api_validation$body_value,
    c(map_id = "query")
  )
  params <- base::list("map_id" = map_id)
  if (base::is.character(params[["map_id"]]) && base::any(!base::nzchar(params[["map_id"]]))) {
    base::stop("Empty query parameter: map_id")
  }
  result <- .ct_request(
    method = "GET",
    path = "/reaction/mapid",
    path_params = base::list(),
    query = base::list("map_id" = params[["map_id"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
