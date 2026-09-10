#' Stdizer Groups
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_groups()
#' }
# Generated with specmill; do not edit by hand.
chemi_stdizer_groups <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "stdizer/groups",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}

#' Stdizer Groups
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param acl Optional parameter
#' @param description Optional parameter
#' @param flag Optional parameter
#' @param frozen Optional parameter
#' @param id Optional parameter
#' @param invalid Optional parameter
#' @param invalidMessage Optional parameter
#' @param operations Optional parameter
#' @param text Optional parameter
#' @param type Optional parameter. Options: METHOD, SMIRKS, SMILES, SMARTS, GROUP, REFERENCE
#' @param value Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.replace Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_bulk(acl = "DTXSID1024122")
#' }
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
  params <- list(
    "acl" = acl,
    "description" = description,
    "flag" = flag,
    "frozen" = frozen,
    "id" = id,
    "invalid" = invalid,
    "invalidMessage" = invalidMessage,
    "operations" = operations,
    "text" = text,
    "type" = type,
    "value" = value,
    "request.filesInfo" = request.filesInfo,
    "request.replace" = request.replace
  )
  result <- generic_chemi_request(
    "query" = params[["acl"]],
    "endpoint" = "stdizer/groups",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "description" = params[["description"]],
          "flag" = params[["flag"]],
          "frozen" = params[["frozen"]],
          "id" = params[["id"]],
          "invalid" = params[["invalid"]],
          "invalidMessage" = params[["invalidMessage"]],
          "operations" = params[["operations"]],
          "text" = params[["text"]],
          "type" = params[["type"]],
          "value" = params[["value"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
