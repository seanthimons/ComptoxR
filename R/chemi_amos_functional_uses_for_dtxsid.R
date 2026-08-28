#' Returns a list of functional use classifications for a substance.
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
#' chemi_amos_functional_uses_for_dtxsid(dtxsid = "DTXSID7020182")
#' }
chemi_amos_functional_uses_for_dtxsid <- function(dtxsid) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_functional_uses_for_dtxsid", "pre_request", list(params = list(`dtxsid` = dtxsid, `server` = server)))
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
    endpoint = "amos/functional_uses_for_dtxsid/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
