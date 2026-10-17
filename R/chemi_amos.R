#' Retrieves a list of records from the database that contain a searched DTXSID.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid The DTXSID for the substance of interest. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos <- function(dtxsid) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(
      dtxsid = list(
        type = "array",
        items = list(
          description = "The DTXSID for the substance of interest.",
          "in" = "path",
          name = "dtxsid",
          type = "string"
        )
      )
    ),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/search/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
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
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = "drop"
  )
}
