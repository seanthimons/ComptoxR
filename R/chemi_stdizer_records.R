#' Stdizer Records
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param full Optional parameter
#' @param options Optional parameter
#' @param records Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_records(full = "DTXSID1024122")
#' }
chemi_stdizer_records <- function(full = NULL, options = NULL, records = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_stdizer_records", "pre_request", list(params = list(`full` = full, `options` = options, `records` = records, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("full" %in% names(req_data$params)) {
    full <- req_data$params[["full"]]
  }
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("records" %in% names(req_data$params)) {
    records <- req_data$params[["records"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(options)) options$options <- options
  if (!is.null(records)) options$records <- records
  result <- generic_chemi_request(
    query = full,
    endpoint = "stdizer/records",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
