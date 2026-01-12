#' Returns the number of records of the given type.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param record_type Record type.  Accepted values are "analytical_qc", "fact_sheets", and "methods".
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_type_count(record_type = "DTXSID7020182")
#' }
chemi_amos_record_type_count <- function(record_type) {
  generic_request(
    query = record_type,
    endpoint = "amos/record_type_count/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


