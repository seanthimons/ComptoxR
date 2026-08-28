#' Returns a list of all unique source names in the database for a specific record type.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_list_sources_by_record_type()
#' }
chemi_amos_list_sources_by_record_type <- function() {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_list_sources_by_record_type", "pre_request", list(params = list(`server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    endpoint = "amos/list_sources_by_record_type/",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
