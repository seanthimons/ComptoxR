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
chemi_services_collated_report <- function(alertRequest = NULL, chemicals = NULL, exportAlerts = NULL, exportHazard = NULL, exportHazard2 = NULL, exportPrediction = NULL, exportSafety = NULL, hazardRequest = NULL, predictionRequest = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_services_collated_report", "pre_request", list(params = list(`alertRequest` = alertRequest, `chemicals` = chemicals, `exportAlerts` = exportAlerts, `exportHazard` = exportHazard, `exportHazard2` = exportHazard2, `exportPrediction` = exportPrediction, `exportSafety` = exportSafety, `hazardRequest` = hazardRequest, `predictionRequest` = predictionRequest, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("alertRequest" %in% names(req_data$params)) {
    alertRequest <- req_data$params[["alertRequest"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("exportAlerts" %in% names(req_data$params)) {
    exportAlerts <- req_data$params[["exportAlerts"]]
  }
  if ("exportHazard" %in% names(req_data$params)) {
    exportHazard <- req_data$params[["exportHazard"]]
  }
  if ("exportHazard2" %in% names(req_data$params)) {
    exportHazard2 <- req_data$params[["exportHazard2"]]
  }
  if ("exportPrediction" %in% names(req_data$params)) {
    exportPrediction <- req_data$params[["exportPrediction"]]
  }
  if ("exportSafety" %in% names(req_data$params)) {
    exportSafety <- req_data$params[["exportSafety"]]
  }
  if ("hazardRequest" %in% names(req_data$params)) {
    hazardRequest <- req_data$params[["hazardRequest"]]
  }
  if ("predictionRequest" %in% names(req_data$params)) {
    predictionRequest <- req_data$params[["predictionRequest"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) options$chemicals <- chemicals
  if (!is.null(exportAlerts)) options$exportAlerts <- exportAlerts
  if (!is.null(exportHazard)) options$exportHazard <- exportHazard
  if (!is.null(exportHazard2)) options$exportHazard2 <- exportHazard2
  if (!is.null(exportPrediction)) options$exportPrediction <- exportPrediction
  if (!is.null(exportSafety)) options$exportSafety <- exportSafety
  if (!is.null(hazardRequest)) options$hazardRequest <- hazardRequest
  if (!is.null(predictionRequest)) options$predictionRequest <- predictionRequest
  result <- generic_chemi_request(
    query = alertRequest,
    endpoint = "services/collated_report",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
