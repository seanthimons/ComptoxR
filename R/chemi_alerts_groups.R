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
  result <- generic_request(
    query = NULL,
    endpoint = "alerts/groups/",
    method = "GET",
    batch_limit = NULL,
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
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups()
#' }
chemi_alerts_groups <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "alerts/groups",
    method = "GET",
    batch_limit = NULL,
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
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups_bulk()
#' }
chemi_alerts_groups_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "alerts/groups",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


