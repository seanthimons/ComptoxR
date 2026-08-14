#' Retrieves a list of records from the ElasticSearch database that contain a searched substring
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param substr The substring to search for.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_by_text(substr = "DTXSID7020182")
#' }
chemi_amos_by_text <- function(substr) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_by_text", "pre_request", list(params = list(`substr` = substr, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("substr" %in% names(req_data$params)) {
    substr <- req_data$params[["substr"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = substr,
    endpoint = "amos/search_by_text/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
