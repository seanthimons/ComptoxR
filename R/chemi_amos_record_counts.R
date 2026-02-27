#' Returns a dictionary containing the counts of record types that are present in the database for each supplied DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids List of DTXSIDs to search for.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_counts(dtxsids = "DTXSID7020182")
#' }
chemi_amos_record_counts <- function(dtxsids = NULL) {

  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "amos/record_counts_by_dtxsid/",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


