#' Returns a list of DTXSIDs for the given functional use
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param functional_class Functional use class. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_functional_class_search(functional_class = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_functional_class_search <- function(functional_class) {
  functional_class <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(functional_class)
  if (base::is.null(functional_class)) {
    base::stop("Required input: functional_class")
  }
  .api_validation$parameter_values(
    base::list("functional_class" = functional_class),
    list(
      functional_class = list(
        type = "array",
        items = list(description = "Functional use class.", "in" = "path", name = "functional_class", type = "string")
      )
    ),
    .api_validation$body_value,
    c(functional_class = "path")
  )
  params <- base::list("functional_class" = functional_class)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/functional_class_search/{functional_class}",
      path_params = base::list("functional_class" = params[["functional_class"]]),
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
      params["functional_class"] <- base::list(chunk)
      send(params)
    },
    params[["functional_class"]],
    1L,
    on_error = "drop"
  )
}
