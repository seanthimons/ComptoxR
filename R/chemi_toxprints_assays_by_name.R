#' Toxprints Assays
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param name name Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_by_name(name = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_assays_by_name <- function(name) {
  name <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(name)
  if (base::is.null(name)) {
    base::stop("Required input: name")
  }
  .api_validation$parameter_values(
    base::list("name" = name),
    list(name = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(name = "path")
  )
  params <- base::list("name" = name)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/toxprints/assays/{name}",
      path_params = base::list("name" = params[["name"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_list",
      server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      auth = list()
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["name"] <- base::list(chunk)
      send(params)
    },
    params[["name"]],
    1L,
    on_error = "drop"
  )
}
