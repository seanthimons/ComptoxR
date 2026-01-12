#' Takes a mass range, methodology, and mass spectrum, and returns all spectra that match the mass and methodology, with entropy similarities between the database spectra and the user-supplied one.
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
#' chemi_amos_mass_spectrum_similarity(query = "DTXSID7020182")
#' }
chemi_amos_mass_spectrum_similarity <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/mass_spectrum_similarity_search/",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


