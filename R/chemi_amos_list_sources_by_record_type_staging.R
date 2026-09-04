#' Returns a list of all unique source names in the database for a specific record type.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param record_type Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_list_sources_by_record_type_staging(record_type = "DTXSID7020182")
#' }
chemi_amos_list_sources_by_record_type_staging <- function(record_type) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_list_sources_by_record_type_staging", "pre_request", list(params = list(`record_type` = record_type, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("record_type" %in% names(req_data$params)) {
    record_type <- req_data$params[["record_type"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = record_type,
    endpoint = "amos/list_sources_by_record_type/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
