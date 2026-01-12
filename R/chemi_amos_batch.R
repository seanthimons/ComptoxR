#' Generates an Excel workbook which lists all records in the database that contain a given set of DTXSIDs.
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
#' chemi_amos_batch(query = "DTXSID7020182")
#' }
chemi_amos_batch <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/batch_search",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


