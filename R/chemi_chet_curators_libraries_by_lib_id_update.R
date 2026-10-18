#' Update one library and its detail definitions
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param lib_id lib_id
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_curators_libraries_by_lib_id_update <- function(lib_id, body) {
  if (base::is.null(lib_id)) {
    base::stop("Required input: lib_id")
  }
  .api_validation$parameter_values(
    base::list("lib_id" = lib_id),
    list(lib_id = list(type = "string")),
    .api_validation$body_value,
    c(lib_id = "path")
  )
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(body, list(additionalProperties = TRUE, type = "object")),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("lib_id" = lib_id, "body" = body)
  result <- .ct_request(
    method = "PUT",
    path = "/curators/libraries/{lib_id}",
    path_params = base::list("lib_id" = params[["lib_id"]]),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
