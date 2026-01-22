#' Takes a mass range, methodology, and mass spectrum, and returns all spectra that match the mass and methodology, with entropy similarities between the database spectra and the user-supplied one.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectrum_similarity()
#' }
chemi_amos_mass_spectrum_similarity <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "amos/mass_spectrum_similarity_search/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


