#' Services Collated Report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
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
#' @examples
#' \dontrun{
#' chemi_services_collated_report(alertRequest = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
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
  params <- list(
    "alertRequest" = alertRequest,
    "chemicals" = chemicals,
    "exportAlerts" = exportAlerts,
    "exportHazard" = exportHazard,
    "exportHazard2" = exportHazard2,
    "exportPrediction" = exportPrediction,
    "exportSafety" = exportSafety,
    "hazardRequest" = hazardRequest,
    "predictionRequest" = predictionRequest
  )
  result <- generic_chemi_request(
    "query" = params[["alertRequest"]],
    "endpoint" = "services/collated_report",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "chemicals" = params[["chemicals"]],
          "exportAlerts" = params[["exportAlerts"]],
          "exportHazard" = params[["exportHazard"]],
          "exportHazard2" = params[["exportHazard2"]],
          "exportPrediction" = params[["exportPrediction"]],
          "exportSafety" = params[["exportSafety"]],
          "hazardRequest" = params[["hazardRequest"]],
          "predictionRequest" = params[["predictionRequest"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
