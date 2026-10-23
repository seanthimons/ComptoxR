#' Reaction stats and filters
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param reaction_id reaction_id
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database_stats()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_database_stats <- function(reaction_id = NULL) {
  .api_validation$parameter_values(
    base::list("reaction_id" = reaction_id),
    list(reaction_id = list(type = "string")),
    .api_validation$body_value,
    c(reaction_id = "query")
  )
  params <- base::list("reaction_id" = reaction_id)
  if (base::is.character(params[["reaction_id"]]) && base::any(!base::nzchar(params[["reaction_id"]]))) {
    base::stop("Empty query parameter: reaction_id")
  }
  result <- .ct_request(
    method = "GET",
    path = "/reaction/database/stats",
    path_params = base::list(),
    query = base::list("reaction_id" = params[["reaction_id"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
