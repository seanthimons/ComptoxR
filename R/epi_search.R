#' Search embedded experimental data
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @param limit Optional parameter (default: 20)
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_search(query = "benzene")
#' }
# Generated with specmill; do not edit by hand.
epi_search <- function(query, limit = 20) {
  params <- base::list("query" = query, "limit" = limit)
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/search",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list("query" = params[["query"]], "limit" = params[["limit"]]),
    "body" = NULL,
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "epi_burl", relative = "/"),
    "auth" = NULL,
    "response_policy" = ".ct_static_list"
  )
  result <- run_hook("epi_search", "post_response", base::list(result = result, params = params))
  result
}
