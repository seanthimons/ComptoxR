#' Returns information on substances where the specified substring is in or equal to a name.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param substring A name substring to search by. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_substring(substring = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_substring <- function(substring) {
  if (base::is.null(substring)) {
    base::stop("Required input: substring")
  }
  .api_validation$parameter_values(
    base::list("substring" = substring),
    list(
      substring = list(
        type = "array",
        items = list(description = "A name substring to search by.", "in" = "path", name = "substring", type = "string")
      )
    ),
    .api_validation$body_value,
    c(substring = "path")
  )
  params <- base::list("substring" = substring)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/substring_search/{substring}",
      path_params = base::list("substring" = params[["substring"]]),
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
      params["substring"] <- base::list(chunk)
      send(params)
    },
    params[["substring"]],
    1L,
    on_error = "drop"
  )
}
