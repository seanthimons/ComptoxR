#' Retrieves a list of records from the database that contain a searched DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos(dtxsid = "DTXSID7020182")
#' }
chemi_amos <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "amos/search/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


