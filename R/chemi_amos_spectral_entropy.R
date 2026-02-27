#' Calculates the spectral entropy for a single spectrum.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param spectrum Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_spectral_entropy(spectrum = "DTXSID7020182")
#' }
chemi_amos_spectral_entropy <- function(spectrum = NULL) {

  result <- generic_chemi_request(
    query = spectrum,
    endpoint = "amos/spectral_entropy/",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


