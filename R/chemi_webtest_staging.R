#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_bulk_staging(query = "DTXSID1024122")
#' }
chemi_webtest_bulk_staging <- function(query) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_webtest_bulk_staging",
    "pre_request",
    list(params = list(`query` = query, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = query,
    endpoint = "webtest",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100")),
    server = server
  )

  return(result)
}
