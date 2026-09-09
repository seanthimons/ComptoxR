#' Alerts Alerts
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_alerts_alerts()
#' }
# Generated with apipak; do not edit by hand.
chemi_alerts_alerts <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "alerts/alerts",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
