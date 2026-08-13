#' Retrieves a PDF from the database by the internal ID and type of record.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param record_type A string indicating which kind of record is being retrieved.  Valid values are 'fact sheet', 'method', and 'spectrum'.
#' @param internal_id Unique ID of the document of interest.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_pdf_staging(record_type = "DTXSID7020182")
#' }
chemi_amos_get_pdf_staging <- function(record_type, internal_id = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_get_pdf_staging",
    "pre_request",
    list(params = list(`record_type` = record_type, `internal_id` = internal_id, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("record_type" %in% names(req_data$params)) {
    record_type <- req_data$params[["record_type"]]
  }
  if ("internal_id" %in% names(req_data$params)) {
    internal_id <- req_data$params[["internal_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = record_type,
    endpoint = "amos/get_pdf/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(internal_id = internal_id)
  )

  # Additional post-processing can be added here

  return(result)
}
