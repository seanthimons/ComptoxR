#' Predictor Modelset Report
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param report_id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_modelset_report(report_id = "DTXSID7020182")
#' }
chemi_predictor_modelset_report <- function(report_id) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_predictor_modelset_report",
    "pre_request",
    list(params = list(`report_id` = report_id, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("report_id" %in% names(req_data$params)) {
    report_id <- req_data$params[["report_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = report_id,
    endpoint = "predictor/modelset_report/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
