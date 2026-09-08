#' Services Collated Report
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param alertRequest Optional parameter
#' @param chemicals Optional parameter
#' @param exportAlerts Optional parameter
#' @param exportHazard Optional parameter
#' @param exportHazard2 Optional parameter
#' @param exportPrediction Optional parameter
#' @param exportSafety Optional parameter
#' @param hazardRequest Optional parameter
#' @param predictionRequest Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_collated_report(alertRequest = "DTXSID1024122")
#' }
chemi_services_collated_report <- function(
  alertRequest = NULL,
  chemicals = NULL,
  exportAlerts = NULL,
  exportHazard = NULL,
  exportHazard2 = NULL,
  exportPrediction = NULL,
  exportSafety = NULL,
  hazardRequest = NULL,
  predictionRequest = NULL
) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) {
    options$chemicals <- chemicals
  }
  if (!is.null(exportAlerts)) {
    options$exportAlerts <- exportAlerts
  }
  if (!is.null(exportHazard)) {
    options$exportHazard <- exportHazard
  }
  if (!is.null(exportHazard2)) {
    options$exportHazard2 <- exportHazard2
  }
  if (!is.null(exportPrediction)) {
    options$exportPrediction <- exportPrediction
  }
  if (!is.null(exportSafety)) {
    options$exportSafety <- exportSafety
  }
  if (!is.null(hazardRequest)) {
    options$hazardRequest <- hazardRequest
  }
  if (!is.null(predictionRequest)) {
    options$predictionRequest <- predictionRequest
  }
  result <- generic_chemi_request(
    query = alertRequest,
    endpoint = "services/collated_report",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
