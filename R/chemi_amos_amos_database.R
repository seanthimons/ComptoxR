#' Returns a summary of the records in the database, organized by record types, methodologies, and sources.
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
#' chemi_amos_amos_database(query = "DTXSID7020182")
#' }
chemi_amos_amos_database <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/database_summary/",
    server = "chemi_burl",
    auth = FALSE
  )
}

