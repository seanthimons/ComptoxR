#' Search reactions and chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query query
#' @param searchType searchType
#' @param substringTF substringTF
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction <- function(query = NULL, searchType = NULL, substringTF = NULL) {
  .api_validation$parameter_values(
    base::list("query" = query, "searchType" = searchType, "substringTF" = substringTF),
    list(query = list(type = "string"), searchType = list(type = "string"), substringTF = list(type = "string")),
    .api_validation$body_value,
    c(query = "query", searchType = "query", substringTF = "query")
  )
  params <- base::list("query" = query, "searchType" = searchType, "substringTF" = substringTF)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["searchType"]]) && base::any(!base::nzchar(params[["searchType"]]))) {
    base::stop("Empty query parameter: searchType")
  }
  if (base::is.character(params[["substringTF"]]) && base::any(!base::nzchar(params[["substringTF"]]))) {
    base::stop("Empty query parameter: substringTF")
  }
  result <- .ct_request(
    method = "GET",
    path = "/reaction/search",
    path_params = base::list(),
    query = base::list(
      "query" = params[["query"]],
      "searchType" = params[["searchType"]],
      "substringTF" = params[["substringTF"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
