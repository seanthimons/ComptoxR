#' Returns a list of record IDs that are associated with the given DTXSID.  This is intended to help when filtering
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid The DTXSID for the substance of interest. Accepts a vector: one request is sent per element and the results are combined.
#' @param record_type The record type of interest.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_record_ids_for_substance(dtxsid = "DTXSID7020182", record_type = "method")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_record_ids_for_substance <- function(dtxsid, record_type) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  if (base::is.null(record_type)) {
    base::stop("Required input: record_type")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "record_type" = record_type),
    list(
      dtxsid = list(
        type = "array",
        items = list(
          description = "The DTXSID for the substance of interest.",
          "in" = "path",
          name = "dtxsid",
          type = "string"
        )
      ),
      record_type = list(
        description = "The record type of interest.",
        "in" = "path",
        name = "record_type",
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(dtxsid = "path", record_type = "path")
  )
  params <- base::list("dtxsid" = dtxsid, "record_type" = record_type)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/record_ids_for_substance/{dtxsid}/{record_type}",
      path_params = base::list("dtxsid" = params[["dtxsid"]], "record_type" = params[["record_type"]]),
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
