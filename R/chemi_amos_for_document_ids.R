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
#' @apiStage public
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
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
