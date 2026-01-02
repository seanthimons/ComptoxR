#' Returns a list of DTXSIDs for the given functional use.
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
#' chemi_amos_amos_dtxsids_for_functional_use(query = "DTXSID7020182")
#' }
chemi_amos_amos_dtxsids_for_functional_use <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/dtxsids_for_functional_use/",
    server = "chemi_burl",
    auth = FALSE
  )
}

