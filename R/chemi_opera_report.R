#' Generate a standalone OPERA calculation report
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox substance identifier
#' @param modelId Dashboard model ID for the OPERA endpoint
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_opera_report(dtxsid = "DTXSID7020182")
#' }
chemi_opera_report <- function(dtxsid, modelId) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_opera_report", "pre_request", list(params = list(`dtxsid` = dtxsid, `modelId` = modelId, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsid" %in% names(req_data$params)) {
    dtxsid <- req_data$params[["dtxsid"]]
  }
  if ("modelId" %in% names(req_data$params)) {
    modelId <- req_data$params[["modelId"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(dtxsid)) options[['dtxsid']] <- dtxsid
  if (!is.null(modelId)) options[['modelId']] <- modelId
    result <- generic_request(
    endpoint = "opera/report",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
