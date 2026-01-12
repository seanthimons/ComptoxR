#' Given a list of DTXSIDs, return all mass spectra for those substances.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectra_for_substances(query = "DTXSID7020182")
#' }
chemi_amos_mass_spectra_for_substances <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/mass_spectra_for_substances/",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


