#' Predictor Qmrf
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param qmrf_id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_qmrf(qmrf_id = "DTXSID7020182")
#' }
chemi_predictor_qmrf <- function(qmrf_id) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_predictor_qmrf",
    "pre_request",
    list(params = list(`qmrf_id` = qmrf_id, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("qmrf_id" %in% names(req_data$params)) {
    qmrf_id <- req_data$params[["qmrf_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = qmrf_id,
    endpoint = "predictor/qmrf/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
