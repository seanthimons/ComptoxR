#' Resolver Getannotation
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param name name
#' @param heading heading
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getannotation(name = "DTXSID7020182", heading = "benzene")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_getannotation <- function(name, heading) {
  if (base::is.null(name)) {
    base::stop("Required input: name")
  }
  if (base::is.null(heading)) {
    base::stop("Required input: heading")
  }
  .api_validation$parameter_values(
    base::list("name" = name, "heading" = heading),
    list(name = list(type = "string"), heading = list(type = "string")),
    .api_validation$body_value,
    c(name = "query", heading = "query")
  )
  params <- base::list("name" = name, "heading" = heading)
  if (base::is.character(params[["name"]]) && base::any(!base::nzchar(params[["name"]]))) {
    base::stop("Empty query parameter: name")
  }
  if (base::is.character(params[["heading"]]) && base::any(!base::nzchar(params[["heading"]]))) {
    base::stop("Empty query parameter: heading")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/getannotation",
    path_params = base::list(),
    query = base::list("name" = params[["name"]], "heading" = params[["heading"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
