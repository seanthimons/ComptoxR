#' Returns a list of DTXSIDs associated with the specified internal ID, along with additional substance information.
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
#' chemi_amos_amos_find_dtxsids(query = "DTXSID7020182")
#' }
chemi_amos_amos_find_dtxsids <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/find_dtxsids/",
    server = "chemi_burl",
    auth = FALSE
  )
}

