#' Verify a DTXSID against DSSTOX
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_verify(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_verify <- function(dtxsid) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(dtxsid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemicals/verify/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_list",
      server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
      auth = list()
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = "drop"
  )
}
