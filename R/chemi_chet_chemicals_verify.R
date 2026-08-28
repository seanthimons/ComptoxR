#' Verify a DTXSID against DSSTOX
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Primary query parameter. Type: string
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_verify(dtxsid = "DTXSID7020182")
#' }
chemi_chet_chemicals_verify <- function(dtxsid) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_chemicals_verify", "pre_request", list(params = list(`dtxsid` = dtxsid, `server` = server)))
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
    endpoint = "chemicals/verify/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
