#' Returns a dictionary containing the counts of record types that are present in the database for each supplied DTXSID.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsids List of DTXSIDs to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_record_counts(dtxsids = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_record_counts <- function(dtxsids = NULL) {
  params <- list("dtxsids" = dtxsids)
  result <- generic_chemi_request(
    "query" = params[["dtxsids"]],
    "endpoint" = "amos/record_counts_by_dtxsid/",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
