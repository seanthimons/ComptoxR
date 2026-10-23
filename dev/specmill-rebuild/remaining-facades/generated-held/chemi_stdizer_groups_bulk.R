# Generated with specmill; do not edit by hand.
chemi_stdizer_groups_bulk <- function(
  acl = NULL,
  description = NULL,
  flag = NULL,
  frozen = NULL,
  id = NULL,
  invalid = NULL,
  invalidMessage = NULL,
  operations = NULL,
  text = NULL,
  type = NULL,
  value = NULL,
  request.filesInfo = NULL,
  request.replace = NULL
) {
  params <- base::list(
    "acl" = function() acl,
    "description" = function() description,
    "flag" = function() flag,
    "frozen" = function() frozen,
    "id" = function() id,
    "invalid" = function() invalid,
    "invalidMessage" = function() invalidMessage,
    "operations" = function() operations,
    "text" = function() text,
    "type" = function() type,
    "value" = function() value,
    "request.filesInfo" = function() request.filesInfo,
    "request.replace" = function() request.replace
  )
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/stdizer/groups",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      body <- base::list(
        description = params[["description"]](),
        flag = params[["flag"]](),
        frozen = params[["frozen"]](),
        id = params[["id"]](),
        invalid = params[["invalid"]](),
        invalidMessage = params[["invalidMessage"]](),
        operations = params[["operations"]](),
        text = params[["text"]](),
        type = params[["type"]](),
        value = params[["value"]](),
        acl = params[["acl"]]()
      )
      value <- unique(as.vector(body[["acl"]]))
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
              invalid = list(type = "boolean"),
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
      context$endpoint <- "stdizer/groups"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
