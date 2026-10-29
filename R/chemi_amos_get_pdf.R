#' Retrieves a PDF from the database by the internal ID and type of record
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param record_type A string indicating which kind of record is being retrieved.  Valid values are 'fact sheet', 'method', and 'spectrum'. Accepts a vector: one request is sent per element and the results are combined.
#' @param internal_id Unique ID of the document of interest.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_pdf(record_type = "method", internal_id = "1")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_pdf <- function(record_type, internal_id) {
  record_type <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(record_type)
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
        type = "array",
        items = list(
          description = "A string indicating which kind of record is being retrieved.  Valid values are 'fact sheet', 'method', and 'spectrum'.",
          "in" = "path",
          name = "record_type",
          type = "string"
        )
      ),
      internal_id = list(
        description = "Unique ID of the document of interest.",
        "in" = "path",
        name = "internal_id",
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(record_type = "path", internal_id = "path")
  )
  params <- base::list("record_type" = record_type, "internal_id" = internal_id)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/get_pdf/{record_type}/{internal_id}",
      path_params = base::list("record_type" = params[["record_type"]], "internal_id" = params[["internal_id"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_file",
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
