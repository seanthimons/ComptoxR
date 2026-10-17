#' Resolver Ghs List
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param name name
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_ghs_list(name = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_ghs_list <- function(name) {
  if (base::is.null(name)) {
    base::stop("Required input: name")
  }
  .api_validation$parameter_values(
    base::list("name" = name),
    list(name = list(type = "string")),
    .api_validation$body_value,
    c(name = "query")
  )
  params <- base::list("name" = name)
  if (base::is.character(params[["name"]]) && base::any(!base::nzchar(params[["name"]]))) {
    base::stop("Empty query parameter: name")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/ghs-list",
    path_params = base::list(),
    query = base::list("name" = params[["name"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
