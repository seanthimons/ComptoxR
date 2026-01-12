#' Alerts Groups 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Primary query parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups(id = "DTXSID7020182")
#' }
chemi_alerts_groups <- function(id) {
  generic_request(
    query = id,
    endpoint = "alerts/groups/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}




#' Alerts Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups()
#' }
chemi_alerts_groups <- function() {
  generic_request(
    query = NULL,
    endpoint = "alerts/groups",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}




#' Alerts Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Required parameter. Options: METHOD, SMILES, SMARTS, TOXPRINT, HAZARD, PROPERTY, GROUP, REFERENCE
#' @param text Optional parameter
#' @param description Optional parameter
#' @param value Optional parameter
#' @param logicType Optional parameter. Options: NONE, OR, AND, NOT
#' @param operations Optional parameter
#' @param frozen Optional parameter
#' @param id Optional parameter
#' @param name Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups_bulk(type = "DTXSID7020182")
#' }
chemi_alerts_groups_bulk <- function(type, text = NULL, description = NULL, value = NULL, logicType = NULL, operations = NULL, frozen = NULL, id = NULL, name = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(text)) options$text <- text
  if (!is.null(description)) options$description <- description
  if (!is.null(value)) options$value <- value
  if (!is.null(logicType)) options$logicType <- logicType
  if (!is.null(operations)) options$operations <- operations
  if (!is.null(frozen)) options$frozen <- frozen
  if (!is.null(id)) options$id <- id
  if (!is.null(name)) options$name <- name
  generic_chemi_request(
    query = type,
    endpoint = "alerts/groups",
    options = options,
    tidy = FALSE
  )
}


