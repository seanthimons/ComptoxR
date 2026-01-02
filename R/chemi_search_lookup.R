#' 
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
#' chemi_search_lookup(query = "DTXSID7020182")
#' }
chemi_search_lookup <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/search/lookup",
    server = "chemi_burl",
    auth = FALSE
  )
}

