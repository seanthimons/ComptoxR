#' Runs a search for document IDs that pass a list of submitted filters, including document metadata, substance
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param record_type Record type to filter by.  Should be either 'Fact Sheet', 'Method', 'Product Declaration', or 'Safety Data Sheet' (capitalization included).. Type: string
#' @param search_info Required parameter
#' @param record_info_fields Optional parameter
#' @param table_fields Optional parameter
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_for_document_ids_development(record_type = "DTXSID7020182")
#' }
chemi_amos_for_document_ids_development <- function(record_type, search_info, record_info_fields = NULL, table_fields = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_for_document_ids_development", "pre_request", list(params = list(`record_type` = record_type, `search_info` = search_info, `record_info_fields` = record_info_fields, `table_fields` = table_fields, `server` = server)))
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
  # Build request body
  request_body <- list()
  request_body$search_info <- search_info
  if (!is.null(record_info_fields)) request_body$record_info_fields <- record_info_fields
  if (!is.null(table_fields)) request_body$table_fields <- table_fields
  result <- generic_request(
    query = NULL,
    endpoint = "amos/search_for_document_ids/",
    method = "POST",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(record_type = record_type),
    body = request_body
  )

  # Additional post-processing can be added here

  return(result)
}
