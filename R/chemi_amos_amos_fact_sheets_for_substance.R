#' Returns a list of fact sheet IDs that are associated with the given DTXSID.
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
#' chemi_amos_amos_fact_sheets_for_substance(query = "DTXSID7020182")
#' }
chemi_amos_amos_fact_sheets_for_substance <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/fact_sheets_for_substance/",
    server = "chemi_burl",
    auth = FALSE
  )
}

