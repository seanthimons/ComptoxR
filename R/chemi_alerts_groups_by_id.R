#' Alerts Groups
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_alerts_groups_by_id(id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_alerts_groups_by_id <- function(id) {
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  .api_validation$parameter_values(
    base::list("id" = id),
    list(id = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(id = "path")
  )
  params <- base::list("id" = id)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/alerts/groups/{id}",
      path_params = base::list("id" = params[["id"]]),
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
      params["id"] <- base::list(chunk)
      send(params)
    },
    params[["id"]],
    1L,
    on_error = "drop"
  )
}
