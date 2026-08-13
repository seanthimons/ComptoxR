#' Retrieves a list of records from the database that contain a searched DTXSID.
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
#' chemi_amos(dtxsid = "DTXSID7020182")
#' }
chemi_amos <- function(dtxsid) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos", "pre_request", list(params = list(`dtxsid` = dtxsid, `server` = server)))
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
    endpoint = "amos/search/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
