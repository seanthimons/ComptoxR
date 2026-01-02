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
#' chemi_resolver_resolver_export_append(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_export_append <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/export-append",
    server = "chemi_burl",
    auth = FALSE
  )
}

