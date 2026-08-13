#' Returns a list of fact sheet IDs that are associated with the given DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_fact_sheets_for_substance(dtxsid = "DTXSID7020182")
#' }
chemi_amos_fact_sheets_for_substance <- function(dtxsid) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_fact_sheets_for_substance",
    "pre_request",
    list(params = list(`dtxsid` = dtxsid, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsid" %in% names(req_data$params)) {
    dtxsid <- req_data$params[["dtxsid"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = dtxsid,
    endpoint = "amos/fact_sheets_for_substance/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
