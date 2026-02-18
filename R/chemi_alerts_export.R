#' Export alerts results
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param alertResult Alert result data to export.
#' @param format Export format (e.g., "json", "csv", "xlsx").
#' @param collapse Whether to collapse results (default: FALSE).
#' @param showDetails Whether to show details (default: FALSE).
#' @param showAlertsOnly Whether to show only alerts (default: FALSE).
#' @param showImages Whether to include images in export (default: FALSE).
#' @return Returns export data
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_export(alertResult = result, format = "csv")
#' }
chemi_alerts_export <- function(alertResult, format = "json", collapse = FALSE, showDetails = FALSE, showAlertsOnly = FALSE, showImages = FALSE) {

  # Build request body
  body <- list(
    alertResult = alertResult,
    format = format,
    collapse = collapse,
    showDetails = showDetails,
    showAlertsOnly = showAlertsOnly,
    showImages = showImages
  )

  result <- generic_chemi_request(
    query = NULL,
    endpoint = "alerts/export",
    options = body,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}

