#' Searches for a record in the database by ID.
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
#' chemi_amos_amos_record_id(query = "DTXSID7020182")
#' }
chemi_amos_amos_record_id <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/record_id_search/",
    server = "chemi_burl",
    auth = FALSE
  )
}

