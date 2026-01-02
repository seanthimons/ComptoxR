#' Generates an Excel workbook which lists all records in the database that contain a given set of DTXSIDs.
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
#' chemi_amos_amos_batch(query = "DTXSID7020182")
#' }
chemi_amos_amos_batch <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/batch_search",
    server = "chemi_burl",
    auth = FALSE
  )
}

