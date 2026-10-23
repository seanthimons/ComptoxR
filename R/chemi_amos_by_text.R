#' Retrieves a list of records from the ElasticSearch database that contain a searched substring
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param substr The substring to search for. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_by_text(substr = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_by_text <- function(substr) {
  substr <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(substr)
  if (base::is.null(substr)) {
    base::stop("Required input: substr")
  }
  .api_validation$parameter_values(
    base::list("substr" = substr),
    list(
      substr = list(
        type = "array",
        items = list(description = "The substring to search for.", "in" = "path", name = "substr", type = "string")
      )
    ),
    .api_validation$body_value,
    c(substr = "path")
  )
  params <- base::list("substr" = substr)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/search_by_text/{substr}",
      path_params = base::list("substr" = params[["substr"]]),
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
      params["substr"] <- base::list(chunk)
      send(params)
    },
    params[["substr"]],
    1L,
    on_error = "drop"
  )
}
