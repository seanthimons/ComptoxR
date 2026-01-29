#' Takes a mass range, methodology, and mass spectrum, and returns all spectra that match the mass and methodology, with entropy similarities between the database spectra and the user-supplied one.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lower_mass_limit Lower limit of the mass range to search for.
#' @param methodology Analytical methodology to search for.  Values aside from "GC/MS" and "LC/MS" are highly unlikely to produce results.
#' @param spectrum Array of two-element numeric arrays.  The two-element arrays represent a single peak in the spectrum, in the format [m/z, intensity].  Peaks should be sorted in ascending order of m/z values.
#' @param type Type of mass window to use for entropy similarity calculations.  Can be either "da" or "ppm".
#' @param upper_mass_limit Upper limit of the mass range to search for.
#' @param window Size of mass window.  Is in units of `type`.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectrum_similarity(lower_mass_limit = c("DTXSID40515441", "DTXSID701030449", "DTXSID9032537"))
#' }
chemi_amos_mass_spectrum_similarity <- function(lower_mass_limit = NULL, methodology = NULL, spectrum = NULL, type = NULL, upper_mass_limit = NULL, window = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(methodology)) options$methodology <- methodology
  if (!is.null(spectrum)) options$spectrum <- spectrum
  if (!is.null(type)) options$type <- type
  if (!is.null(upper_mass_limit)) options$upper_mass_limit <- upper_mass_limit
  if (!is.null(window)) options$window <- window
  result <- generic_chemi_request(
    query = lower_mass_limit,
    endpoint = "amos/mass_spectrum_similarity_search/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


