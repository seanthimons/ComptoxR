#' Creates an Excel workbook listing the substances in the specified record with some additional identifiers.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_id Unique ID of the record of interest.
#' @return Decoded JSON, text, or raw workbook bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_amos_get_substance_file_for_record <- function(internal_id) {
  if (base::is.null(internal_id)) {
    base::stop("Required input: internal_id")
  }
  .api_validation$parameter_values(
    base::list("internal_id" = internal_id),
    list(
      internal_id = list(
        description = "Unique ID of the record of interest.",
        "in" = "path",
        name = "internal_id",
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(internal_id = "path")
  )
  params <- base::list("internal_id" = internal_id)
  result <- .ct_request(
    method = "GET",
    path = "/api/amos/get_substance_file_for_record/{internal_id}",
    path_params = base::list("internal_id" = params[["internal_id"]]),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
