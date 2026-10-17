#' Returns a list of record IDs that are associated with the given DTXSID.  This is intended to help when filtering
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @param record_type The record type of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_ids_for_substance(dtxsid = "DTXSID7020182")
#' }
chemi_amos_record_ids_for_substance <- function(dtxsid, record_type = NULL) {
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
