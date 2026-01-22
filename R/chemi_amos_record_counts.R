#' Returns a dictionary containing the counts of record types that are present in the database for each supplied DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_counts()
#' }
chemi_amos_record_counts <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "amos/record_counts_by_dtxsid/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


