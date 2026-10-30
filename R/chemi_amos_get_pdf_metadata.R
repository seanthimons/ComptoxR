#' Retrieves metadata associated with a PDF record
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param record_type A string indicating which kind of record is being retrieved. Valid values are 'spectrum', 'fact sheet', and 'method'.
#' @param internal_id Unique ID of the PDF of interest.
#' @return Decoded JSON, text, or raw workbook bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_amos_get_pdf_metadata <- function(record_type, internal_id) {
  if (base::is.null(record_type)) {
    base::stop("Required input: record_type")
  }
  if (base::is.null(internal_id)) {
    base::stop("Required input: internal_id")
  }
  .api_validation$parameter_values(
    base::list("record_type" = record_type, "internal_id" = internal_id),
    list(
      record_type = list(
        description = "A string indicating which kind of record is being retrieved. Valid values are 'spectrum', 'fact sheet', and 'method'.",
        "in" = "path",
        name = "record_type",
        type = "string"
      ),
      internal_id = list(
        description = "Unique ID of the PDF of interest.",
        "in" = "path",
        name = "internal_id",
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(record_type = "path", internal_id = "path")
  )
  params <- base::list("record_type" = record_type, "internal_id" = internal_id)
  result <- .ct_request(
    method = "GET",
    path = "/api/amos/get_pdf_metadata/{record_type}/{internal_id}",
    path_params = base::list("record_type" = params[["record_type"]], "internal_id" = params[["internal_id"]]),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
