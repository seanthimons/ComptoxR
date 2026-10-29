#' Return details attached to a library through detail sets for ChemReg reaction editor
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param lib_id lib_id
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_editor_library_details <- function(lib_id) {
  if (base::is.null(lib_id)) {
    base::stop("Required input: lib_id")
  }
  .api_validation$parameter_values(
    base::list("lib_id" = lib_id),
    list(lib_id = list(type = "string")),
    .api_validation$body_value,
    c(lib_id = "query")
  )
  params <- base::list("lib_id" = lib_id)
  if (base::is.character(params[["lib_id"]]) && base::any(!base::nzchar(params[["lib_id"]]))) {
    base::stop("Empty query parameter: lib_id")
  }
  result <- .ct_request(
    method = "GET",
    path = "/reaction/editor/library-details",
    path_params = base::list(),
    query = base::list("lib_id" = params[["lib_id"]]),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
