#' Alerts
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param options Required parameter
#' @param chemicals Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts(options = "DTXSID7020182")
#' }
chemi_alerts <- function(options, chemicals = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) options$chemicals <- chemicals
  generic_chemi_request(
    query = options,
    endpoint = "alerts",
    options = options,
    tidy = FALSE
  )
}


