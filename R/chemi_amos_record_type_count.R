#' Returns the number of records of the given type.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param record_type Record type.  Accepted values are "analytical_qc", "fact_sheets", and "methods". Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_record_type_count(record_type = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_record_type_count <- function(record_type) {
  if (base::is.null(record_type)) {
    base::stop("Required input: record_type")
  }
  .api_validation$parameter_values(
    base::list("record_type" = record_type),
    list(
      record_type = list(
        type = "array",
        items = list(
          description = "Record type.  Accepted values are \"analytical_qc\", \"fact_sheets\", and \"methods\".",
          "in" = "path",
          name = "record_type",
          type = "string"
        )
      )
    ),
    .api_validation$body_value,
    c(record_type = "path")
  )
  params <- base::list("record_type" = record_type)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/record_type_count/{record_type}",
      path_params = base::list("record_type" = params[["record_type"]]),
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
      params["record_type"] <- base::list(chunk)
      send(params)
    },
    params[["record_type"]],
    1L,
    on_error = "drop"
  )
}
