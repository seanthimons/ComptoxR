#' Returns substance(s) that match a search term.
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
#' chemi_amos_amos_get_substances_for_term(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_substances_for_term <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_substances_for_search_term/",
    server = "chemi_burl",
    auth = FALSE
  )
}

