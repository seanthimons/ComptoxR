#' Fetch a single chemical
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_singlechemical(dtxsid = "DTXSID7020182")
#' }
chemi_chet_chemicals_singlechemical <- function(dtxsid = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_chemicals_singlechemical", "pre_request", list(params = list(`dtxsid` = dtxsid, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsid" %in% names(req_data$params)) {
    dtxsid <- req_data$params[["dtxsid"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(dtxsid)) options[['dtxsid']] <- dtxsid
    result <- generic_request(
    endpoint = "chemicals/singlechemical",
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
