#' Build reaction map
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id
#' @param searchtype searchtype
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_reactionmap()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_reactionmap <- function(id = NULL, searchtype = NULL) {
  .api_validation$parameter_values(
    base::list("id" = id, "searchtype" = searchtype),
    list(id = list(type = "string"), searchtype = list(type = "string")),
    .api_validation$body_value,
    c(id = "query", searchtype = "query")
  )
  params <- base::list("id" = id, "searchtype" = searchtype)
  if (base::is.character(params[["id"]]) && base::any(!base::nzchar(params[["id"]]))) {
    base::stop("Empty query parameter: id")
  }
  if (base::is.character(params[["searchtype"]]) && base::any(!base::nzchar(params[["searchtype"]]))) {
    base::stop("Empty query parameter: searchtype")
  }
  result <- .ct_request(
    method = "GET",
    path = "/reaction/reactionmap",
    path_params = base::list(),
    query = base::list("id" = params[["id"]], "searchtype" = params[["searchtype"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
