#' Alerts Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups()
#' }
chemi_alerts_groups <- function() {
  result <- generic_request(
    endpoint = "alerts/groups",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


#' Alerts Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
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
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups_bulk(description = "DTXSID1024122")
#' }
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
  # Build options list for additional parameters
  options <- list()
  if (!is.null(frozen)) {
    options$frozen <- frozen
  }
  if (!is.null(id)) {
    options$id <- id
  }
  if (!is.null(logicType)) {
    options$logicType <- logicType
  }
  if (!is.null(name)) {
    options$name <- name
  }
  if (!is.null(operations)) {
    options$operations <- operations
  }
  if (!is.null(text)) {
    options$text <- text
  }
  if (!is.null(type)) {
    options$type <- type
  }
  if (!is.null(value)) {
    options$value <- value
  }
  result <- generic_chemi_request(
    query = description,
    endpoint = "alerts/groups",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
