# Generated with specmill; do not edit by hand.
chemi_alerts_groups_bulk <- function(
  description = NULL,
  frozen = NULL,
  id = NULL,
  logicType = NULL,
  name = NULL,
  operations = NULL,
  text = NULL,
  type = NULL,
  value = NULL
) {
  params <- base::list(
    "description" = function() description,
    "frozen" = function() frozen,
    "id" = function() id,
    "logicType" = function() logicType,
    "name" = function() name,
    "operations" = function() operations,
    "text" = function() text,
    "type" = function() type,
    "value" = function() value
  )
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/alerts/groups",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      body <- base::list(
        frozen = params[["frozen"]](),
        id = params[["id"]](),
        logicType = params[["logicType"]](),
        name = params[["name"]](),
        operations = params[["operations"]](),
        text = params[["text"]](),
        type = params[["type"]](),
        value = params[["value"]](),
        description = params[["description"]]()
      )
      value <- unique(as.vector(body[["description"]]))
      value <- value[!is.na(value) & value != ""]
      if (!length(value)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      body <- base::Filter(base::Negate(base::is.null), body)
      body <- .api_validation$body_value(
        body,
        structure(
          list(
            properties = list(
              description = list(type = "string"),
              frozen = list(type = "boolean"),
              id = list(type = "string"),
              logicType = list(enum = list("NONE", "OR", "AND", "NOT"), type = "string"),
              name = list(type = "string"),
              operations = list(
                items = structure(
                  list(
                    properties = list(
                      description = list(type = "string"),
                      text = list(type = "string"),
                      type = list(
                        enum = list(
                          "METHOD",
                          "SMILES",
                          "SMARTS",
                          "TOXPRINT",
                          "HAZARD",
                          "PROPERTY",
                          "GROUP",
                          "REFERENCE"
                        ),
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
              type = list(
                enum = list("METHOD", "SMILES", "SMARTS", "TOXPRINT", "HAZARD", "PROPERTY", "GROUP", "REFERENCE"),
                type = "string"
              ),
              value = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/LibraryGroup"
        )
      )
      if (FALSE) {
        list(body)
      } else {
        body
      }
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        httr2::resp_check_status(response)
      }
      context$endpoint <- "alerts/groups"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
