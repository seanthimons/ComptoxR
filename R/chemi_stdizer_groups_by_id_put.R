#' Standardizer groupUpdatePut
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
chemi_stdizer_groups_by_id_put <- function(id, body) {
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
              acl = structure(
                list(
                  properties = list(
                    access = list(enum = list("PUBLIC", "AUTHENTICATED", "PRIVATE"), type = "string"),
                    owner = list(type = "string"),
                    read = list(items = list(type = "string"), type = "array"),
                    write = list(items = list(type = "string"), type = "array")
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/ACL"
              ),
              description = list(type = "string"),
              flag = list(type = "string"),
              frozen = list(type = "boolean"),
              id = list(type = "string"),
              invalid = list(
                type = "boolean"
              ),
              invalidMessage = list(type = "string"),
              operations = list(
                items = structure(
                  list(
                    properties = list(
                      description = list(type = "string"),
                      flag = list(type = "string"),
                      invalid = list(type = "boolean"),
                      invalidMessage = list(type = "string"),
                      text = list(type = "string"),
                      type = list(
                        enum = list("METHOD", "SMIRKS", "SMILES", "SMARTS", "GROUP", "REFERENCE"),
                        type = "string"
                      )
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/Operation"
                ),
                type = "array"
              ),
              text = list(type = "string"),
              type = list(enum = list("METHOD", "SMIRKS", "SMILES", "SMARTS", "GROUP", "REFERENCE"), type = "string"),
              value = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/LibraryGroup"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("id" = id, "body" = body)
  result <- .ct_request(
    method = "PUT",
    path = "/api/stdizer/groups/{id}",
    path_params = base::list("id" = params[["id"]]),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
