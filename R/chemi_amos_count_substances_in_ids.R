#' Counts the number of unique substances seen in a set of records.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_count_substances_in_ids(query = "DTXSID7020182")
#' }
chemi_amos_count_substances_in_ids <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/count_substances_in_ids/",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


