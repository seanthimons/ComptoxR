#' Retrieves a list of records from the database that contain a searched DTXSID.
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
#' chemi_amos_amos(query = "DTXSID7020182")
#' }
chemi_amos_amos <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/search/",
    server = "chemi_burl",
    auth = FALSE
  )
}

