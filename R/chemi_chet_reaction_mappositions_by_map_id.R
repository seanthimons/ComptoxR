#' Delete stored reaction-map node positions
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param map_id map_id
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_mappositions_by_map_id <- function(map_id) {
  if (base::is.null(map_id)) {
    base::stop("Required input: map_id")
  }
  .api_validation$parameter_values(
    base::list("map_id" = map_id),
    list(map_id = list(type = "string")),
    .api_validation$body_value,
    c(map_id = "path")
  )
  params <- base::list("map_id" = map_id)
  result <- .ct_request(
    method = "DELETE",
    path = "/reaction/mappositions/{map_id}",
    path_params = base::list("map_id" = params[["map_id"]]),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
