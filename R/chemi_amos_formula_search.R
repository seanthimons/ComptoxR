#' Returns a list of substances that have the given molecular formula.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula Molecular formula to search by.  Formula should be in Hill form. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_formula_search(formula = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_formula_search <- function(formula) {
  formula <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(formula)
  if (base::is.null(formula)) {
    base::stop("Required input: formula")
  }
  .api_validation$parameter_values(
    base::list("formula" = formula),
    list(
      formula = list(
        type = "array",
        items = list(
          description = "Molecular formula to search by.  Formula should be in Hill form.",
          "in" = "path",
          name = "formula",
          type = "string"
        )
      )
    ),
    .api_validation$body_value,
    c(formula = "path")
  )
  params <- base::list("formula" = formula)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/formula_search/{formula}",
      path_params = base::list("formula" = params[["formula"]]),
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
      params["formula"] <- base::list(chunk)
      send(params)
    },
    params[["formula"]],
    1L,
    on_error = "drop"
  )
}
