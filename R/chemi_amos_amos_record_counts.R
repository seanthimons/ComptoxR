#' Returns a dictionary containing the counts of record types that are present in the database for each supplied DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_amos_record_counts(query = "DTXSID7020182")
#' }
chemi_amos_amos_record_counts <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/record_counts_by_dtxsid/",
    server = "chemi_burl",
    auth = FALSE
  )
}

