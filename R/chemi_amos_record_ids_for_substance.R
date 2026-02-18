#' Get record IDs for a substance by DTXSID and record type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DTXSID of the substance.
#' @param record_type Type of record to retrieve.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_ids_for_substance(dtxsid = "DTXSID7020182", record_type = "fact_sheet")
#' }
chemi_amos_record_ids_for_substance <- function(dtxsid, record_type) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "amos/record_ids_for_substance/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(record_type = record_type)
  )

  # Additional post-processing can be added here

  return(result)
}

