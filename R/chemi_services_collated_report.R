#' Services Collated Report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param alertRequest JSON string for the report field.
#' @param chemicals JSON string for the report field.
#' @param exportAlerts Logical export flag.
#' @param exportHazard Logical export flag.
#' @param exportHazard2 Logical export flag.
#' @param exportPrediction Logical export flag.
#' @param exportSafety Logical export flag.
#' @param hazardRequest JSON string for the report field.
#' @param predictionRequest JSON string for the report field.
#' @return Decoded JSON, text, or raw report bytes according to the response content type.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
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
  params <- base::list(
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
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/services/collated_report",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = .ct_services_body(
      params,
      structure(
        list(
          properties = list(
            alertRequest = list(type = "string"),
            chemicals = list(type = "string"),
            exportAlerts = list(type = "boolean"),
            exportHazard = list(type = "boolean"),
            exportHazard2 = list(type = "boolean"),
            exportPrediction = list(type = "boolean"),
            exportSafety = list(type = "boolean"),
            hazardRequest = list(type = "string"),
            predictionRequest = list(type = "string")
          ),
          type = "object"
        ),
        specmill_id = "#/components/schemas/ExportCollatedReportRequest"
      )
    ),
    "headers" = list(Accept = "*/*"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
