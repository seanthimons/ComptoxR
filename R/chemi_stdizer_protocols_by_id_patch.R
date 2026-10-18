#' Standardizer protocolCuratePatch
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id
#' @param body Request body.
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_protocols_by_id_patch <- function(id, body) {
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  .api_validation$parameter_values(
    base::list("id" = id),
    list(id = list(type = "string")),
    .api_validation$body_value,
    c(id = "path")
  )
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(
        body,
        structure(
          list(
            properties = list(
              comment = list(type = "string"),
              curationStatus = list(enum = list("NONE", "CORRECT", "INCORRECT", "QUESTIONABLE"), type = "string"),
              ordinals = list(items = list(format = "int32", type = "integer"), type = "array")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/CurateProtocolRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("id" = id, "body" = body)
  result <- .ct_request(
    method = "PATCH",
    path = "/api/stdizer/protocols/{id}",
    path_params = base::list("id" = params[["id"]]),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
