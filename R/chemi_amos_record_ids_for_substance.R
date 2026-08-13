#' Returns a list of record IDs that are associated with the given DTXSID.  This is intended to help when filtering
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @param record_type The record type of interest.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_ids_for_substance(dtxsid = "DTXSID7020182")
#' }
chemi_amos_record_ids_for_substance <- function(dtxsid, record_type = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_record_ids_for_substance",
    "pre_request",
    list(params = list(`dtxsid` = dtxsid, `record_type` = record_type, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsid" %in% names(req_data$params)) {
    dtxsid <- req_data$params[["dtxsid"]]
  }
  if ("record_type" %in% names(req_data$params)) {
    record_type <- req_data$params[["record_type"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = dtxsid,
    endpoint = "amos/record_ids_for_substance/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(record_type = record_type)
  )

  # Additional post-processing can be added here

  return(result)
}
