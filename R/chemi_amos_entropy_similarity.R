#' Calculates the entropy similarity for two spectra.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param spectrum_1 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param spectrum_2 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param type Type of mass window to use.  Should be either "da" or "ppm".
#' @param window Size of the mass window to use.  Will be in units of the 'type' argument.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_entropy_similarity(spectrum_1 = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_entropy_similarity <- function(spectrum_1 = NULL, spectrum_2 = NULL, type = NULL, window = NULL) {
  params <- list("spectrum_1" = spectrum_1, "spectrum_2" = spectrum_2, "type" = type, "window" = window)
  result <- generic_chemi_request(
    "query" = params[["spectrum_1"]],
    "endpoint" = "amos/entropy_similarity/",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("spectrum_2" = params[["spectrum_2"]], "type" = params[["type"]], "window" = params[["window"]])
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
