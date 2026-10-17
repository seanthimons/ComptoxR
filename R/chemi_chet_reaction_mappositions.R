#' Fetch stored reaction-map node positions
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param map_id map_id Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mappositions(map_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_mappositions <- function(map_id) {
  if (base::is.null(map_id)) {
    base::stop("Required input: map_id")
  }
  .api_validation$parameter_values(
    base::list("map_id" = map_id),
    list(map_id = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(map_id = "path")
  )
  params <- base::list("map_id" = map_id)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/reaction/mappositions/{map_id}",
      path_params = base::list("map_id" = params[["map_id"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_list",
      server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
      auth = list()
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["map_id"] <- base::list(chunk)
      send(params)
    },
    params[["map_id"]],
    1L,
    on_error = "drop"
  )
}
