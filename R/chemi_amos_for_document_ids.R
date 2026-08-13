#' Runs a search for document IDs that pass a list of submitted filters, including document metadata, substance
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param record_type Record type to filter by.  Should be either 'Fact Sheet', 'Method', 'Product Declaration', or 'Safety Data Sheet' (capitalization included).
#' @param search_info Search query parameters.  Exact parameters are still in flux, but generally consist of database field names with values and flags for whether to perform exact matches or not.
#' @param record_info_fields List of field names in search_info that are fields in the record_info table in PostgreSQL.
#' @param table_fields List of field names in search_info that are fields in the fact_sheets table in PostgreSQL.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_for_document_ids(record_type = "DTXSID1024122")
#' }
chemi_amos_for_document_ids <- function(
  record_type,
  search_info = NULL,
  record_info_fields = NULL,
  table_fields = NULL
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_for_document_ids",
    "pre_request",
    list(
      params = list(
        `record_type` = record_type,
        `search_info` = search_info,
        `record_info_fields` = record_info_fields,
        `table_fields` = table_fields,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("record_type" %in% names(req_data$params)) {
    record_type <- req_data$params[["record_type"]]
  }
  if ("search_info" %in% names(req_data$params)) {
    search_info <- req_data$params[["search_info"]]
  }
  if ("record_info_fields" %in% names(req_data$params)) {
    record_info_fields <- req_data$params[["record_info_fields"]]
  }
  if ("table_fields" %in% names(req_data$params)) {
    table_fields <- req_data$params[["table_fields"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(search_info)) {
    options[['search_info']] <- search_info
  }
  if (!is.null(record_info_fields)) {
    options[['record_info_fields']] <- record_info_fields
  }
  if (!is.null(table_fields)) {
    options[['table_fields']] <- table_fields
  }
  result <- generic_chemi_request(
    query = record_type,
    endpoint = "amos/search_for_document_ids/",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
