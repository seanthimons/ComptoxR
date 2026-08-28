#' Search Gethazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param sid Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_gethazard(sid = "DTXSID7020182")
#' }
chemi_search_gethazard <- function(sid) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_search_gethazard", "pre_request", list(params = list(`sid` = sid, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("sid" %in% names(req_data$params)) {
    sid <- req_data$params[["sid"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(sid)) options[['sid']] <- sid
    result <- generic_request(
    endpoint = "search/gethazard",
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
