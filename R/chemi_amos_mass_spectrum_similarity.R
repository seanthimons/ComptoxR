#' Takes a mass range, methodology, and mass spectrum, and returns all spectra that match the mass and methodology, with entropy similarities between the database spectra and the user-supplied one.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param lower_mass_limit Lower limit of the mass range to search for.
#' @param methodology Analytical methodology to search for.  Values aside from "GC/MS" and "LC/MS" are highly unlikely to produce results.
#' @param spectrum Array of two-element numeric arrays.  The two-element arrays represent a single peak in the spectrum, in the format \[m/z, intensity\].  Peaks should be sorted in ascending order of m/z values.
#' @param type Type of mass window to use for entropy similarity calculations.  Can be either "da" or "ppm".
#' @param upper_mass_limit Upper limit of the mass range to search for.
#' @param window Size of mass window.  Is in units of \code{type}.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectrum_similarity(lower_mass_limit = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_mass_spectrum_similarity <- function(
  lower_mass_limit = NULL,
  methodology = NULL,
  spectrum = NULL,
  type = NULL,
  upper_mass_limit = NULL,
  window = NULL
) {
  params <- list(
    "lower_mass_limit" = lower_mass_limit,
    "methodology" = methodology,
    "spectrum" = spectrum,
    "type" = type,
    "upper_mass_limit" = upper_mass_limit,
    "window" = window
  )
  result <- generic_chemi_request(
    "query" = params[["lower_mass_limit"]],
    "endpoint" = "amos/mass_spectrum_similarity_search/",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "methodology" = params[["methodology"]],
          "spectrum" = params[["spectrum"]],
          "type" = params[["type"]],
          "upper_mass_limit" = params[["upper_mass_limit"]],
          "window" = params[["window"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
