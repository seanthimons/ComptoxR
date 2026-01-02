#' Returns the number of spectra that have a specified methodology.
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
#' chemi_amos_amos_spectrum_count_for_methodology(query = "DTXSID7020182")
#' }
chemi_amos_amos_spectrum_count_for_methodology <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/spectrum_count_for_methodology/",
    server = "chemi_burl",
    auth = FALSE
  )
}

