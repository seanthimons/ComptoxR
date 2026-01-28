#' Given a list of DTXSIDs, return all mass spectra for those substances.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectra_for_substances()
#' }
chemi_amos_mass_spectra_for_substances <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/mass_spectra_for_substances/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


