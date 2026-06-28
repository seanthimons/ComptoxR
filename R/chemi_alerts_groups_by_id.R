#' Alerts Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups_by_id(id = "DTXSID7020182")
#' }
chemi_alerts_groups_by_id <- function(id) {
  result <- generic_request(
    query = id,
    endpoint = "alerts/groups/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
