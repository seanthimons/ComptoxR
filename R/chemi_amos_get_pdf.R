#' Retrieves a PDF from the database by the internal ID and type of record.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param record_type A string indicating which kind of record is being retrieved.  Valid values are 'fact sheet', 'method', and 'spectrum pdf'.
#' @param internal_id Unique ID of the document of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_pdf(record_type = "DTXSID7020182")
#' }
chemi_amos_get_pdf <- function(record_type, internal_id = NULL) {
  generic_request(
    query = record_type,
    endpoint = "amos/get_pdf/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(internal_id = internal_id)
  )
}


