#' Resolver lookupCASRN
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query query
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_lookupCASRN(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_lookupCASRN <- function(query) {
  if (base::is.null(query)) {
    base::stop("Required input: query")
  }
  .api_validation$parameter_values(
    base::list("query" = query),
    list(query = list(type = "string")),
    .api_validation$body_value,
    c(query = "query")
  )
  params <- base::list("query" = query)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/lookupCASRN",
    path_params = base::list(),
    query = base::list("query" = params[["query"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
