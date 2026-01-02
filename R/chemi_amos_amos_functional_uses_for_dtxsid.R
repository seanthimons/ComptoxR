#' Returns a list of functional use classifications for a substance.
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
#' chemi_amos_amos_functional_uses_for_dtxsid(query = "DTXSID7020182")
#' }
chemi_amos_amos_functional_uses_for_dtxsid <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/functional_uses_for_dtxsid/",
    server = "chemi_burl",
    auth = FALSE
  )
}

