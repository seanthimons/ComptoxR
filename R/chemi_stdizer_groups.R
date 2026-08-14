#' Stdizer Groups
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
#' chemi_stdizer_groups()
#' }
chemi_stdizer_groups <- function() {
  result <- generic_request(
    endpoint = "stdizer/groups",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


#' Stdizer Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
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
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_bulk(acl = "DTXSID1024122")
#' }
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
  value = NULL
) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(description)) {
    options$description <- description
  }
  if (!is.null(flag)) {
    options$flag <- flag
  }
  if (!is.null(frozen)) {
    options$frozen <- frozen
  }
  if (!is.null(id)) {
    options$id <- id
  }
  if (!is.null(invalid)) {
    options$invalid <- invalid
  }
  if (!is.null(invalidMessage)) {
    options$invalidMessage <- invalidMessage
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
    query = acl,
    endpoint = "stdizer/groups",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
