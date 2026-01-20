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
  result <- generic_request(
    query = NULL,
    endpoint = "stdizer/groups/",
    method = "GET",
    batch_limit = NULL,
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
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups()
#' }
chemi_stdizer_groups <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "stdizer/groups",
    method = "GET",
    batch_limit = NULL,
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
#' @param request.filesInfo Required parameter
#' @param request.replace Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_bulk(request.filesInfo = "DTXSID7020182")
#' }
chemi_stdizer_groups_bulk <- function(request.filesInfo, request.replace = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request.filesInfo)) options[['request.filesInfo']] <- request.filesInfo
  if (!is.null(request.replace)) options[['request.replace']] <- request.replace
    result <- generic_chemi_request(
    query = NULL,
    endpoint = "stdizer/groups",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


