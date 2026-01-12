#' Returns an Excel file containing a deduplicated list of substances that appear in a given set of database record IDs.
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
#' chemi_amos_substances_for_ids(query = "DTXSID7020182")
#' }
chemi_amos_substances_for_ids <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/substances_for_ids/",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


