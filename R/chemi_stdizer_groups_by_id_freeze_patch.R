#' Standardizer groupFreezePatch
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id
#' @param freeze freeze
#' @param hierarchically hierarchically
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_groups_by_id_freeze_patch <- function(id, freeze = TRUE, hierarchically = TRUE) {
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  .api_validation$parameter_values(
    base::list("id" = id, "freeze" = freeze, "hierarchically" = hierarchically),
    list(
      id = list(type = "string"),
      freeze = list(default = TRUE, type = "boolean"),
      hierarchically = list(default = TRUE, type = "boolean")
    ),
    .api_validation$body_value,
    c(id = "path", freeze = "query", hierarchically = "query")
  )
  params <- base::list("id" = id, "freeze" = freeze, "hierarchically" = hierarchically)
  if (base::is.character(params[["freeze"]]) && base::any(!base::nzchar(params[["freeze"]]))) {
    base::stop("Empty query parameter: freeze")
  }
  if (base::is.character(params[["hierarchically"]]) && base::any(!base::nzchar(params[["hierarchically"]]))) {
    base::stop("Empty query parameter: hierarchically")
  }
  result <- .ct_request(
    method = "PATCH",
    path = "/api/stdizer/groups/{id}/freeze",
    path_params = base::list("id" = params[["id"]]),
    query = base::list("freeze" = params[["freeze"]], "hierarchically" = params[["hierarchically"]]),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    parameter_serialization = list(
      list(
        name = "freeze",
        location = "query",
        schema = list(default = TRUE, type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = FALSE
      ),
      list(
        name = "hierarchically",
        location = "query",
        schema = list(default = TRUE, type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = FALSE
      )
    )
  )
  result
}
