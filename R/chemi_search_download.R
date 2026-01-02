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
#' chemi_search_download(query = "DTXSID7020182")
#' }
chemi_search_download <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/search/download",
    server = "chemi_burl",
    auth = FALSE
  )
}

