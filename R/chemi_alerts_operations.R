#' Alerts Operations
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_alerts_operations()
#' }
# Generated with apipak; do not edit by hand.
chemi_alerts_operations <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "alerts/operations",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
