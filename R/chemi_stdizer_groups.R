#' Stdizer Groups 
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
#' chemi_stdizer_groups(id = "DTXSID7020182")
#' }
chemi_stdizer_groups <- function(id) {
  generic_request(
    query = id,
    endpoint = "stdizer/groups/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}




#' Stdizer Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups()
#' }
chemi_stdizer_groups <- function() {
  generic_request(
    query = NULL,
    endpoint = "stdizer/groups",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}




#' Stdizer Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Required parameter. Options: METHOD, SMIRKS, SMILES, SMARTS, GROUP, REFERENCE
#' @param text Optional parameter
#' @param description Optional parameter
#' @param flag Optional parameter
#' @param invalid Optional parameter
#' @param invalidMessage Optional parameter
#' @param operations Optional parameter
#' @param frozen Optional parameter
#' @param id Optional parameter
#' @param value Optional parameter
#' @param acl Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_bulk(type = "DTXSID7020182")
#' }
chemi_stdizer_groups_bulk <- function(type, text = NULL, description = NULL, flag = NULL, invalid = NULL, invalidMessage = NULL, operations = NULL, frozen = NULL, id = NULL, value = NULL, acl = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(text)) options$text <- text
  if (!is.null(description)) options$description <- description
  if (!is.null(flag)) options$flag <- flag
  if (!is.null(invalid)) options$invalid <- invalid
  if (!is.null(invalidMessage)) options$invalidMessage <- invalidMessage
  if (!is.null(operations)) options$operations <- operations
  if (!is.null(frozen)) options$frozen <- frozen
  if (!is.null(id)) options$id <- id
  if (!is.null(value)) options$value <- value
  if (!is.null(acl)) options$acl <- acl
  generic_chemi_request(
    query = type,
    endpoint = "stdizer/groups",
    options = options,
    tidy = FALSE
  )
}


