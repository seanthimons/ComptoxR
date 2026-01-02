#' Endpoint for retrieving a specified NMR spectrum from the database.
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
#' chemi_amos_amos_get_nmr_spectrum(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_nmr_spectrum <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_nmr_spectrum/",
    server = "chemi_burl",
    auth = FALSE
  )
}

