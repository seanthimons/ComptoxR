#' Calculates the spectral entropy for a single spectrum.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param spectrum Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_spectral_entropy(spectrum = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_spectral_entropy <- function(spectrum = NULL) {
  params <- list("spectrum" = spectrum)
  result <- generic_chemi_request(
    "query" = params[["spectrum"]],
    "endpoint" = "amos/spectral_entropy/",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
