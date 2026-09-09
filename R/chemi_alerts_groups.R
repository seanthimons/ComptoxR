#' Alerts Groups
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_alerts_groups()
#' }
# Generated with apipak; do not edit by hand.
chemi_alerts_groups <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "alerts/groups",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}

#' Alerts Groups
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param description Optional parameter
#' @param frozen Optional parameter
#' @param id Optional parameter
#' @param logicType Optional parameter. Options: NONE, OR, AND, NOT
#' @param name Optional parameter
#' @param operations Optional parameter
#' @param text Optional parameter
#' @param type Optional parameter. Options: METHOD, SMILES, SMARTS, TOXPRINT, HAZARD, PROPERTY, GROUP, REFERENCE
#' @param value Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_alerts_groups_bulk(description = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
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
  params <- list(
    "description" = description,
    "frozen" = frozen,
    "id" = id,
    "logicType" = logicType,
    "name" = name,
    "operations" = operations,
    "text" = text,
    "type" = type,
    "value" = value
  )
  result <- generic_chemi_request(
    "query" = params[["description"]],
    "endpoint" = "alerts/groups",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "frozen" = params[["frozen"]],
          "id" = params[["id"]],
          "logicType" = params[["logicType"]],
          "name" = params[["name"]],
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
