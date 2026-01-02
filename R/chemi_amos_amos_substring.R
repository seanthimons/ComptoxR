#' Returns information on substances where the specified substring is in or equal to a name.
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
#' chemi_amos_amos_substring(query = "DTXSID7020182")
#' }
chemi_amos_amos_substring <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/substring_search/",
    server = "chemi_burl",
    auth = FALSE
  )
}

