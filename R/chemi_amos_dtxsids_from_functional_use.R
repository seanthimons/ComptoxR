#' Returns all substances associated with the specified functional use classification.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param functional_use Functional use classification to search for. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids_from_functional_use(functional_use = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_dtxsids_from_functional_use <- function(functional_use) {
  functional_use <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(functional_use)
  if (base::is.null(functional_use)) {
    base::stop("Required input: functional_use")
  }
  .api_validation$parameter_values(
    base::list("functional_use" = functional_use),
    list(
      functional_use = list(
        type = "array",
        items = list(
          description = "Functional use classification to search for.",
          "in" = "path",
          name = "functional_use",
          type = "string"
        )
      )
    ),
    .api_validation$body_value,
    c(functional_use = "path")
  )
  params <- base::list("functional_use" = functional_use)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/dtxsids_from_functional_use/{functional_use}",
      path_params = base::list("functional_use" = params[["functional_use"]]),
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
      params["functional_use"] <- base::list(chunk)
      send(params)
    },
    params[["functional_use"]],
    1L,
    on_error = "drop"
  )
}
