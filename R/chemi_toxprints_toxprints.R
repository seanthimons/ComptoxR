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
#' chemi_toxprints_toxprints(query = "DTXSID7020182")
#' }
chemi_toxprints_toxprints <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/toxprints",
    server = "chemi_burl",
    auth = FALSE
  )
}

