#' Returns substance information and record counts for a list of DTXSIDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids Array of DTXSIDs as strings.
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids_development(dtxsids = "DTXSID1024122")
#' }
chemi_amos_dtxsids_development <- function(dtxsids = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_dtxsids_development", "pre_request", list(params = list(`dtxsids` = dtxsids, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsids" %in% names(req_data$params)) {
    dtxsids <- req_data$params[["dtxsids"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "amos/dtxsids/",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
