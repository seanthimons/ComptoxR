#' Alerts Alerts
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_alerts()
#' }
chemi_alerts_alerts <- function() {
  generic_request(
    query = NULL,
    endpoint = "alerts/alerts",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


