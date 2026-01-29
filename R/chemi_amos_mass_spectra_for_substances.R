#' Given a list of DTXSIDs, return all mass spectra for those substances.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids List of DTXSIDs to search for.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectra_for_substances(dtxsids = c("DTXSID10894891", "DTXSID10894750", "DTXSID4048141"))
#' }
chemi_amos_mass_spectra_for_substances <- function(dtxsids = NULL) {

  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "amos/mass_spectra_for_substances/",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


