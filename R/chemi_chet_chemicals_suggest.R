#' Suggest CheT chemicals for look-ahead search
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query query
#' @param limit limit
#' @param only_in_reactions only_in_reactions
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_suggest(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_suggest <- function(query, limit = 8L, only_in_reactions = "true") {
  if (base::is.null(query)) {
    base::stop("Required input: query")
  }
  .api_validation$parameter_values(
    base::list("query" = query, "limit" = limit, "only_in_reactions" = only_in_reactions),
    list(
      query = list(type = "string"),
      limit = list(default = 8L, maximum = 25L, minimum = 1L, type = "integer"),
      only_in_reactions = list(default = "true", type = "string")
    ),
    .api_validation$body_value,
    c(query = "query", limit = "query", only_in_reactions = "query")
  )
  params <- base::list("query" = query, "limit" = limit, "only_in_reactions" = only_in_reactions)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["limit"]]) && base::any(!base::nzchar(params[["limit"]]))) {
    base::stop("Empty query parameter: limit")
  }
  if (base::is.character(params[["only_in_reactions"]]) && base::any(!base::nzchar(params[["only_in_reactions"]]))) {
    base::stop("Empty query parameter: only_in_reactions")
  }
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/suggest",
    path_params = base::list(),
    query = base::list(
      "query" = params[["query"]],
      "limit" = params[["limit"]],
      "only_in_reactions" = params[["only_in_reactions"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
