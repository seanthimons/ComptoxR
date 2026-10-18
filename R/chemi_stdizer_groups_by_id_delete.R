#' Standardizer groupDelete
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_groups_by_id_delete <- function(id) {
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  .api_validation$parameter_values(
    base::list("id" = id),
    list(id = list(type = "string")),
    .api_validation$body_value,
    c(id = "path")
  )
  params <- base::list("id" = id)
  result <- .ct_request(
    method = "DELETE",
    path = "/api/stdizer/groups/{id}",
    path_params = base::list("id" = params[["id"]]),
    query = base::list(),
    body = NULL,
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
