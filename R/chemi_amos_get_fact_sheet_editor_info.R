#' Retrieves metadata from the database about a single fact sheet.  This is not necessarily just the metadata that
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the fact sheet of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_fact_sheet_editor_info(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_fact_sheet_editor_info <- function(internal_id) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_get_fact_sheet_editor_info", "pre_request", list(params = list(`internal_id` = internal_id, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("internal_id" %in% names(req_data$params)) {
    internal_id <- req_data$params[["internal_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = internal_id,
    endpoint = "amos/get_fact_sheet_editor_info/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
