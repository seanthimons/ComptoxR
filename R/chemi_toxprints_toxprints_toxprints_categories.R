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
#' chemi_toxprints_toxprints_toxprints_categories(query = "DTXSID7020182")
#' }
chemi_toxprints_toxprints_toxprints_categories <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/toxprints/toxprints_categories",
    server = "chemi_burl",
    auth = FALSE
  )
}

