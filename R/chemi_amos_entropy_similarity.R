#' Calculates the entropy similarity for two spectra.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param spectrum_1 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param spectrum_2 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param type Type of mass window to use.  Should be either "da" or "ppm".
#' @param window Size of the mass window to use.  Will be in units of the 'type' argument.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_entropy_similarity(spectrum_1 = "DTXSID7020182")
#' }
chemi_amos_entropy_similarity <- function(spectrum_1 = NULL, spectrum_2 = NULL, type = NULL, window = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(spectrum_2)) options$spectrum_2 <- spectrum_2
  if (!is.null(type)) options$type <- type
  if (!is.null(window)) options$window <- window
  result <- generic_chemi_request(
    query = spectrum_1,
    endpoint = "amos/entropy_similarity/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


