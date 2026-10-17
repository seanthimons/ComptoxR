#' Returns substance(s) that match a search term.  Since some substance names can have slashes in them, <path> is used
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param search_term A substance identifier.  If it cannot be parsed as an InChIKey, CASRN, or DTXSID, it is assumed to be a name. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_substances_for_term(search_term = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_substances_for_term <- function(search_term) {
  if (base::is.null(search_term)) {
    base::stop("Required input: search_term")
  }
  .api_validation$parameter_values(
    base::list("search_term" = search_term),
    list(
      search_term = list(
        type = "array",
        items = list(
          description = "A substance identifier.  If it cannot be parsed as an InChIKey, CASRN, or DTXSID, it is assumed to be a name.",
          "in" = "path",
          name = "search_term",
          type = "string"
        )
      )
    ),
    .api_validation$body_value,
    c(search_term = "path")
  )
  params <- base::list("search_term" = search_term)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/get_substances_for_search_term/{search_term}",
      path_params = base::list("search_term" = params[["search_term"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_list",
      server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      auth = list()
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["search_term"] <- base::list(chunk)
      send(params)
    },
    params[["search_term"]],
    1L,
    on_error = "drop"
  )
}
